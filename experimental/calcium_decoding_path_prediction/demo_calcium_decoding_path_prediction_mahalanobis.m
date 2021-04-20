% Run the main demo, then run this.

% 2021-03-12
% I'm using Mahalanobis distance instead of the SVM. This seems to work
% much better at classifying the points.

close all
clear all
clc


sessionFolder = 'M:\Minimice\CMG162_CA1\analysis\chengs_task_2c\s3';

%% We train on this trial
iTrialTrain = 4;
[TTraining] = get_training_table(sessionFolder, iTrialTrain)


%% Now we will test on this other trial
iTrialTest = 3;
trialFolders = ml_dir_trial_folders(sessionFolder);

numTrials = length(trialFolders);
sessionTrialFolder = trialFolders{iTrialTest};
s = split(sessionTrialFolder, filesep);
s = s{end};
trial_id = str2double(s(7:end));
fprintf('Processing (%s)\n', sessionTrialFolder);

nfn = fullfile(sessionTrialFolder, 'neuron.hdf5');
[neuronDataset] = ml_cai_neuron_h5_read( nfn );

sfn = fullfile(sessionTrialFolder, 'scope.hdf5');
scopeDataset  = ml_cai_scope_h5_read( sfn );
scope_timestamps_ms = double(scopeDataset.timestamp_ms);

mfn = fullfile(sessionTrialFolder, 'movement.mat');
tmp = load(mfn);
movement = tmp.movement;
cm_per_bin = 2;

if strcmpi( movement.arenaShape, 'rectangle' )
    nbinsx = ceil(movement.arena.x_length_cm / cm_per_bin + 1);
    nbinsy = ceil(movement.arena.y_length_cm / cm_per_bin + 1);

    maxx_cm = movement.arena.x_length_cm;
    maxy_cm = movement.arena.y_length_cm;
else
    error('Invalid shape')
end
boundsx = [0, maxx_cm];
boundsy = [0, maxy_cm];% Discretize the position data so we can bin it
[~, ~, xi, yi, xedges, yedges] = ...
ml_core_compute_binned_positions(movement.x_cm, movement.y_cm, boundsx, boundsy, nbinsx, nbinsy);



%% Reduce TTraining to only the useful data. 
inan = find(isnan(TTraining.neuron_1));
TUse = TTraining;
TUse(inan,:) = []; % remove the rows that are all nan

U = unique(TUse(:,1:3), 'rows');

% We only want bins that were sampled enough
for iU = 1:size(U,1)
   ik = find(ismember(TUse.yi, U.yi(iU)) & ismember(TUse.xi, U.xi(iU)) & ismember(TUse.ind, U.ind(iU)));
   if length(ik) < 5 && ~isempty(ik)
       TUse(ik,:) = [];
   end
end

U = unique(TUse(:,1:3), 'rows');

%%
% Get the times of the path
pos_t = movement.timestamps_ms;
pos_t = pos_t - pos_t(1); % start it at zero
pos_x = movement.x_cm;
pos_y = movement.y_cm;

sim_t = pos_t(1:30:end);
sim_x = pos_x(1:30:end);
sim_y = pos_y(1:30:end);

close all

warning('off', 'MATLAB:nearlySingularMatrix'); % matlab is annoying


for iSim = 1:length(sim_t)-1
    fprintf('Sim %d\n', iSim);
    
    % Get the data for the current time
    t1 = sim_t(iSim);
    t2 = sim_t(iSim+1);
    inds = intersect(find(scope_timestamps_ms >= t1), find(scope_timestamps_ms <= t2));
    
    % Get the feature vector
    fprintf('Computing feature vector ... ');
    fv = zeros(neuronDataset.num_neurons,1);
    for nid = 1:neuronDataset.num_neurons
        neuronName = sprintf('neuron_%d', nid);
        v = neuronDataset.neuron(nid).trace_raw;
       
       if ~isempty(inds)
            av = sum(v(inds), 'all') ./ (t2-t1);
            if ~isfinite(av)
                av = nan;
            end
       else
           av = nan;
       end
       fv(nid) = av;
    end % nid
    fprintf('done!\n');
    
    binIndices = unique(TUse.ind);
    numBinIndices = length(binIndices);
    C = zeros(numBinIndices,1);
    
    for iBin1 = 1:numBinIndices
        for iBin2 = iBin1+1:numBinIndices
            b1 = binIndices(iBin1);
            b2 = binIndices(iBin2);
            %fprintf('Analyzing (%d, %d)\n', b1, b2);
            for n1 = 1:neuronDataset.num_neurons
                for n2 = 1:neuronDataset.num_neurons
                    B1 = get_bin_activity(TUse, b1, n1, n2);
                    B2 = get_bin_activity(TUse, b2, n1, n2);
                    
                    if ~all(isfinite(B1), 'all') || ~all(isfinite(B2), 'all')
                        continue;
                    end
                    
                    if size(B1,1) <= 1 || size(B2,1) <= 1
                        continue; 
                    end

                    F = [fv(n1), fv(n2)];
                    if any(isnan(F))
                        continue;
                    end
                    
                    % Classify points
                    DC1 = mahal(F,B1);
                    DC2 = mahal(F,B2);
                    
                    
                    if DC1 < DC2
                        C(iBin1) = C(iBin1) + 1;
                    else
                        C(iBin2) = C(iBin2) + 1;
                    end
                end % n2
            end % n1
        end % iBin 2
    end % iBin1
    
    M = zeros(max(U.yi), max(U.xi));
    for iC = 1:length(C)
        yi = U.yi(U.ind == binIndices(iC));
        xi = U.xi(U.ind == binIndices(iC));
        M(yi,xi) = M(yi,xi) + C(iC);
    end
    
    h = figure();
    imagesc(M)
    hold on
    plot(xi, yi, 'r*', 'markersize', 10);
    
    title(sprintf('Sim %d', iSim))
    daspect([1,1,1])
    drawnow
    saveas(h, fullfile(pwd, sprintf('frame_%d.png', iSim)));
    close(h);
    
end % iSim

    
    




function [TTraining] = get_training_table(sessionFolder, iTrialTrain)
    trialFolders = ml_dir_trial_folders(sessionFolder);

    numTrials = length(trialFolders);

    trial_stats = {}; % = zeros(1, neuronDataset.num_neurons);

    %iTrialTrain = 2;

    sessionTrialFolder = trialFolders{iTrialTrain};

    s = split(sessionTrialFolder, filesep);
    s = s{end};
    trial_id = str2double(s(7:end));
    fprintf('Processing (%s)\n', sessionTrialFolder);

    nfn = fullfile(sessionTrialFolder, 'neuron.hdf5');
    [neuronDataset] = ml_cai_neuron_h5_read( nfn );

    sfn = fullfile(sessionTrialFolder, 'scope.hdf5');
    scopeDataset  = ml_cai_scope_h5_read( sfn );
    scope_timestamps_ms = double(scopeDataset.timestamp_ms);

    mfn = fullfile(sessionTrialFolder, 'movement.mat');
    tmp = load(mfn);
    movement = tmp.movement;
    cm_per_bin = 2;

    [train] = get_path_bin_transitions(movement, cm_per_bin);
    %[spike_timestamps_ms] = get_neuron_spikes(neuronDataset, scope_timestamps_ms);

    for nid = 1:neuronDataset.num_neurons
        neuronName = sprintf('neuron_%d', nid);
        %st = spike_timestamps_ms{nid};
        v = neuronDataset.neuron(nid).trace_raw;
        rate = zeros(length(train),1);
        for iT = 1:length(train)
           t1 = train(iT).gstart_timestamps_ms;
           t2 = train(iT).gstop_timestamps_ms;

           inds = intersect(find(scope_timestamps_ms >= t1), find(scope_timestamps_ms <= t2));
           if ~isempty(inds)
                av = sum(v(inds), 'all') ./ (t2-t1);
                if ~isfinite(av)
                    av = nan;
                end
           else
               av = nan;
           end
           train(iT).(neuronName) = av;
        end

    end

    TTraining = struct2table(train);

end % function