close all
clear all
clc

USE_REAL_BEHAVIOUR_DATA = false;
%SIM_TYPE = 'tetrode';
SIM_TYPE = 'calcium';

% Settings
video_width_px = 720;
video_height_px = 480;
arena_width_cm = 20;
arena_height_cm = 30;
prob_180_rots = 0.5; % This should be between 0 and 1.
show_field = 0;
numSimCells = 20;
fs = 32000; % sampling rate of neural recordings
noise_rate_hz = 0.5; % Average number of noise spikes per second

dateTag = datestr(now, 'yyyymmdd_HHMMSS');

% Load or simulate behaviour data
if USE_REAL_BEHAVIOUR_DATA
    % Load real behaviour data
    if strcmpi(SIM_TYPE, 'tetrode')
        sessionAnalysisFolder = 'T:\Shamu_two_contexts_CA1\tetrodes\analysis\feature_rich\AK42_CA1\d9';
        dataMatrix = ml_load_real_behaviour_datamatrix(sessionAnalysisFolder);
    else %if strcmpi(SIM_TYPE, 'calcium')
        error('Unsupported');
    end
else
    % Simulate behaivour data
    numSimTrials = 12;
    dataMatrix = ml_sim_behaviour_datamatrix(arena_width_cm, arena_height_cm, numSimTrials);
end

trialIds = sort(unique(dataMatrix(:,1)));
numTrials = max(trialIds);

rotTable = zeros(numSimCells, numTrials);

% Make the flips global
% for iTrial = 1:numTrials
%     if  rand(1) < prob_180_rots
%         for iCell = 1:numSimCells
%             rotTable(iCell,iTrial) = 1;
%         end
%     end
% end

% Make the rotations local (no coherence of rotations between cells)
for iCell = 1:numSimCells
    for iTrial = 1:numTrials
        if  rand(1) < prob_180_rots
            rotTable(iCell,iTrial) = 1;
        end
    end
end

simData = [];

for iCell = 1:numSimCells
   % Create a random placefield within the arena
   placefield = ml_sim_placefield_rand_rect(arena_width_cm, arena_height_cm);
   
   doRotation = rotTable(iCell,:);
   
   % Simulate the spikes
   if strcmpi(SIM_TYPE, 'tetrode')
        cellSpikeTimestamps_s = ml_sim_placefield_tetrode_spikes_rect(placefield, arena_width_cm, arena_height_cm, fs, dataMatrix, doRotation, noise_rate_hz);
        %simData(iCell).spike_timestamps_ms = cellSpikeTimestamps_s*1000.0;
   elseif strcmpi(SIM_TYPE, 'calcium')
        traceMatrix = ml_sim_placefield_calcium_traces_rect(placefield, arena_width_cm, arena_height_cm, fs,dataMatrix, doRotation);
           simData(iCell).traceMatrix = traceMatrix;
   else
       error('unsupported');
   end
   
   simData(iCell).placefield = placefield;
   simData(iCell).doRotation = doRotation;
   
end % iCell

if strcmpi(SIM_TYPE, 'tetrode')
    tfileBits = 64;
    outputFolder = fullfile(pwd, sprintf('%s_%d_%d', dateTag, tfileBits, round(prob_180_rots*100)));
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end
    for iCell = 1:numSimCells
        outputTFullFilename = fullfile(outputFolder, sprintf('TT1_%d.t', iCell));
        ml_sim_mclust_tfile_write(simData(iCell).spike_timestamps_ms, tfileBits, outputTFullFilename);
    end
    fprintf('Simulated t-files saved to directory: %s\n', outputFolder);
    
    nvtOutputFilename = fullfile(outputFolder, 'VT1.nvt');
    [xMax_px, yMax_px] = ml_sim_nlx_nvt_save(dataMatrix(:,2), dataMatrix(:,3), dataMatrix(:,4), arena_width_cm, arena_height_cm, video_width_px, video_height_px, nvtOutputFilename);
    fprintf('Simulated Neuralynx NVT file saved: %s\n', nvtOutputFilename);
end

%%
outputFolder = fullfile(pwd, sprintf('%s_%s_%d', dateTag, 'calcium', round(prob_180_rots*100)));
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end


% Save the full workspace
save(fullfile(outputFolder, 'workspace.mat'));

fnDataMatrix = fullfile(outputFolder, 'dataMatrix.mat');
save(fnDataMatrix, 'dataMatrix');
fprintf('dataMatrix saved: %s\n', fnDataMatrix); 

%% Output the path data for use in the calcium code


% Save ROI to avoid having to manually selecting them with the GUI
% To-do: Rotate the arena like we do in practice. Then this code will need
% to be modified to account for that.
if USE_REAL_BEHAVIOUR_DATA == false % therefore, use sim data
    %xMax_px = [
    for iTrial = 1:numTrials
       trialId = trialIds(iTrial);

       arenaroi.xVertices = [xMax_px; 0; 0; xMax_px];
       arenaroi.yVertices = [0; 0; yMax_px; yMax_px];

       roiFilename = fullfile(outputFolder, sprintf('trial_%d_arenaroi.mat', trialId));
       save(roiFilename, 'arenaroi');
    end
end

%% Plot to see what the results look like
%ml_sim_tetrode_data_plot(outputFolder)

%% Calcium data
function [traceMatrix] = ml_sim_placefield_calcium_traces_rect(placefield, arena_width_cm, arena_height_cm, fs, behaviourDataMatrix, doRotation)
   trialIds = sort(unique(behaviourDataMatrix(:,1)));
   
   cameraFps_hz = 20;
   
   % 
   traceMatrix = [];
   for iTrial = 1:length(trialIds)
        trialId = trialIds(iTrial);
        trialInd = find(behaviourDataMatrix(:,1) == trialId);
        if isempty(trialInd)
            continue;
        end
        behaviour_pos_timestamps_ms = behaviourDataMatrix(trialInd, 2);
        behaviour_pos_x_cm = behaviourDataMatrix(trialInd, 3);
        behaviour_pos_y_cm = behaviourDataMatrix(trialInd, 4);
        
        behaviour_pos_timestamps_s = behaviour_pos_timestamps_ms/1000.0;
        
        trace_timestamps_ms = behaviour_pos_timestamps_ms(1):(1/cameraFps_hz):behaviour_pos_timestamps_ms(end);
        trace_timestamps_ms = reshape(trace_timestamps_ms, numel(trace_timestamps_ms), 1);
        
        numTraceSamples = length(trace_timestamps_ms);
        
        if  ~isempty(doRotation) && doRotation(trialId)
            cxu = abs(arena_width_cm - placefield.center_x_cm);
            cyu = abs(arena_height_cm - placefield.center_y_cm);
        else
            cxu = placefield.center_x_cm;
            cyu = placefield.center_y_cm;
        end
        
        % Distance of the animal for each position sample
        d_cm = sqrt( (behaviour_pos_x_cm - cxu).^2 + (behaviour_pos_y_cm - cyu).^2 );

        rate_behav = normpdf(d_cm, 0, placefield.field_size_cm) * placefield.max_firing_rate_hz;

        tmax_s = max(behaviour_pos_timestamps_s)-1;
        tmin_s = min(behaviour_pos_timestamps_s)+1;
        t_neural = tmin_s:(1/fs):tmax_s;
        rate_neural = interp1(behaviour_pos_timestamps_s, rate_behav, t_neural);
        x = rand(1, length(rate_neural));
        dt = 1 ./ fs;
        spikeIndices = find(x <= rate_neural .* dt);
        spikeTimes_s = t_neural(spikeIndices);
        spikeTimes_s = reshape(spikeTimes_s, numel(spikeTimes_s), 1);
        
        SNR = 100;
        trial_timestamps_ms = trace_timestamps_ms;
        trial_traceWithNoise = ml_sim_cai_trace(trace_timestamps_ms, spikeTimes_s*1000.0, SNR);
        trial_indices = trialId.*ones(numTraceSamples,1);
        
        d = [trial_indices, trial_timestamps_ms, trial_traceWithNoise];
        
        if isempty(traceMatrix)
            traceMatrix = d;
        else
            traceMatrix = [traceMatrix; d];
        end
   end % iTrial
end




function [signal] = ml_sim_cai_trace(timestamps_ms, spikeTimes_ms, SNR)
    numSamples = length(timestamps_ms);
    
    timestamps_s = timestamps_ms / 1000.0;
    spikeTimes_s = spikeTimes_ms / 1000.0;
    
    % Setup transiet model
    tau_50 = 1;
    tau_d = tau_50 / log(2);
    tau_r = 0.2;

    % Noise model
    %SNR = 5;
    sigma = 1 ./ SNR;
    n = mvnrnd(0, sigma, numSamples);
    n = reshape(n, size(timestamps_ms,1), size(timestamps_ms,2));

    numSpikes = length(spikeTimes_s);

    trace = zeros(size(timestamps_ms));

    for iSpike = 1:numSpikes
        spikeTime_s = spikeTimes_s(iSpike);
        [y, ~] = ml_cai_transient_model_exp2(timestamps_s, spikeTime_s, tau_d, tau_r);

        trace = trace + y;
    end
    signal = log(exp(trace) + n);
end % function

function [y, tMax] = ml_cai_transient_model_exp2(t, ts, tau_d, tau_r)
    y = zeros(size(t));
    for iT = 1:length(t)
        if t(iT) >= ts
            y(iT) = (exp(-(t(iT)-ts)/tau_d) - exp(-(t(iT)-ts)/tau_r)) / (tau_d - tau_r);
        end
    end

    ymaxMath = (1/(tau_d-tau_r)) * ( (tau_r/tau_d)^(-tau_r/(tau_r-tau_d)) - (tau_r/tau_d)^(-tau_d/(tau_r-tau_d)) );
    
    % Make unit height
    y = y ./ ymaxMath;
    
    % Find the mathematical maximum
    tMax = ts + log(tau_r/tau_d)/(1/tau_d - 1/tau_r);
end % function


%% Tetrode data
function [cellSpikeTimestamps_s] = ml_sim_placefield_tetrode_spikes_rect(placefield, arena_width_cm, arena_height_cm, fs, dataMatrix, doRotation, noise_rate_hz)
   trialIds = sort(unique(dataMatrix(:,1)));
   
   cellSpikeTimestamps_s = [];
   for iTrial = 1:length(trialIds)
       trialId = trialIds(iTrial);
        trialInd = find(dataMatrix(:,1) == trialId);
        if isempty(trialInd)
            continue;
        end
        behaviour_pos_timestamps_ms = dataMatrix(trialInd, 2);
        behaviour_pos_x_cm = dataMatrix(trialInd, 3);
        behaviour_pos_y_cm = dataMatrix(trialInd, 4);
        
        behaviour_pos_timestamps_s = behaviour_pos_timestamps_ms/1000.0;
        
        if  ~isempty(doRotation) && doRotation(trialId)
            cxu = abs(arena_width_cm - placefield.center_x_cm);
            cyu = abs(arena_height_cm - placefield.center_y_cm);
        else
            cxu = placefield.center_x_cm;
            cyu = placefield.center_y_cm;
        end
        
        % Distance of the animal for each position sample
        d_cm = sqrt( (behaviour_pos_x_cm - cxu).^2 + (behaviour_pos_y_cm - cyu).^2 );

        rate_behav = normpdf(d_cm, 0, placefield.field_size_cm) * placefield.max_firing_rate_hz;

        tmax_s = max(behaviour_pos_timestamps_s)-1;
        tmin_s = min(behaviour_pos_timestamps_s)+1;
        t_neural = tmin_s:(1/fs):tmax_s;
        rate_neural = interp1(behaviour_pos_timestamps_s, rate_behav, t_neural);
        x = rand(1, length(rate_neural));
        dt = 1 ./ fs;
        spikeIndices = find(x <= rate_neural .* dt);
        spikeTimes_s = t_neural(spikeIndices);
        spikeTimes_s = reshape(spikeTimes_s, numel(spikeTimes_s), 1);
        
        trialSpikeTimestamps_s = spikeTimes_s;
        
        
        % Simulate spikes due to noise or bad cuts
        if ~isempty(noise_rate_hz)
           trialDuration_s = tmax_s - tmin_s;
           numNoiseSpikes = round(rand(1) * trialDuration_s * noise_rate_hz);
           if numNoiseSpikes <= 0
               numNoiseSpikes = 1;
           end
           
           noiseSpikeIndices = unique( randi( length(t_neural), numNoiseSpikes, 1 ) );
           
           noiseSpikeTimes_s = t_neural( noiseSpikeIndices );
           noiseSpikeTimes_s = reshape(noiseSpikeTimes_s, numel(noiseSpikeTimes_s), 1);
           
           trialSpikeTimestamps_s = [trialSpikeTimestamps_s; noiseSpikeTimes_s];
        end
        trialSpikeTimestamps_s = sort( unique(trialSpikeTimestamps_s) );
        

        % For the t-files the spike times are not separated by trial
        if isempty(cellSpikeTimestamps_s)
            cellSpikeTimestamps_s = trialSpikeTimestamps_s;
        else
            cellSpikeTimestamps_s = [cellSpikeTimestamps_s; trialSpikeTimestamps_s];
        end
   end % iTrial
end


%% General
function [dataMatrix] = ml_load_real_behaviour_datamatrix(sessionAnalysisFolder)
    files = dir(fullfile(sessionAnalysisFolder, 'trial_*_movement.mat'));
    numTrials = length(files);

   dataMatrix = [];
   % Make the data matrix
   for iTrial = 1:numTrials
        [behaviour_pos_timestamps_ms, behaviour_pos_x_cm, behaviour_pos_y_cm] = ml_load_real_trial_behaviour(sessionAnalysisFolder, iTrial);
        behaviour_pos_timestamps_ms = reshape(behaviour_pos_timestamps_ms, numel(behaviour_pos_timestamps_ms), 1); % columns
        behaviour_pos_x_cm = reshape(behaviour_pos_x_cm, numel(behaviour_pos_x_cm), 1); % columns
        behaviour_pos_y_cm = reshape(behaviour_pos_y_cm, numel(behaviour_pos_y_cm), 1); % columns
        behaviour_trial_id = iTrial * ones(numel(behaviour_pos_timestamps_ms), 1);
        
        dm = [behaviour_trial_id, behaviour_pos_timestamps_ms, behaviour_pos_x_cm, behaviour_pos_y_cm];
        
        if isempty(dataMatrix)
            dataMatrix = dm;
        else
            dataMatrix = [dataMatrix; dm];
        end
   end
end % function


function [behaviour_pos_timestamps_ms, behaviour_pos_x_cm, behaviour_pos_y_cm] = ml_load_real_trial_behaviour(sessionAnalysisFolder, iTrial)
    % The session analysis folder should contain data generated by MuLaNA
    tmp = load(fullfile(sessionAnalysisFolder, sprintf('trial_%d_movement.mat', iTrial)));
    movement = tmp.movement;

    behaviour_pos_timestamps_ms = movement.timestamps_ms;
    behaviour_pos_x_cm = movement.x_cm;
    behaviour_pos_y_cm = movement.y_cm;
    
end % function

function [placefield] = ml_sim_placefield_rand_rect(arena_width_cm, arena_height_cm)
   cx = arena_width_cm*rand(1);
   cy = arena_height_cm*rand(1);
   
   fieldSize = sqrt(3 + (10-3)*rand(1));
   
   mfr = 25;
   
   placefield = ml_sim_placefield_init(cx, cy, fieldSize, mfr);
end % function

function [placefield] = ml_sim_placefield_init(cx, cy, fieldSize, mfr)
   placefield.center_x_cm = cx;
   placefield.center_y_cm = cy;
   placefield.field_size_cm = fieldSize; % std of the field
   placefield.max_firing_rate_hz = mfr;   
end % function