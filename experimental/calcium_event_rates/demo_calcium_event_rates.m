close all
clear all
clc


sessionFolder = 'M:\Minimice\CMG162_CA1\analysis\chengs_task_2c\s1';

trialFolders = ml_dir_trial_folders(sessionFolder);

numTrials = length(trialFolders);

trial_stats = {}; % = zeros(1, neuronDataset.num_neurons);

for iTrial = 1:numTrials
    sessionTrialFolder = trialFolders{iTrial};
    
    s = split(sessionTrialFolder, filesep);
    s = s{end};
    trial_id = str2double(s(7:end));
    fprintf('Processing (%s)\n', sessionTrialFolder);
    
    nfn = fullfile(sessionTrialFolder, 'neuron.hdf5');
    [neuronDataset] = ml_cai_neuron_h5_read( nfn );

    sfn = fullfile(sessionTrialFolder, 'scope.hdf5');
    scopeDataset  = ml_cai_scope_h5_read( sfn );


    timestamps_ms = double(scopeDataset.timestamp_ms);

    for nid = 1:neuronDataset.num_neurons
        it = length(trial_stats) + 1;
        
        trial_stats(it).m = 0;
        trial_stats(it).g = 0;
        trial_stats(it).trial_id = trial_id;
        trial_stats(it).neuron_id = nid;
        
        calciumEvents = [];

        neuron = neuronDataset.neuron(nid);

        spike_timestamps_ms = ml_cai_estimate_spikes(timestamps_ms, neuron.trace_raw);

        if ~isempty(spike_timestamps_ms)

            MAX_SPIKE_SEPARATION_MS = 500;
            calciumEvents = ml_cai_neuron_calcium_events(neuron, timestamps_ms, spike_timestamps_ms, MAX_SPIKE_SEPARATION_MS);
        else
            continue;
        end

        if ~isempty(calciumEvents)
            spike_counts = zeros(size(timestamps_ms));
            for iEvent = 1:length(calciumEvents)
                %events_timestamps_ms = [calciumEvents.timestamps_begin_ms];
                e = calciumEvents(iEvent);
                prevCount = spike_counts(e.timestamps_begin_index:e.timestamps_end_index);
                spike_counts(e.timestamps_begin_index:e.timestamps_end_index) = prevCount + e.num_spikes ./ (e.timestamps_end_ms - e.timestamps_begin_ms) * 1000.0;
            end

            m = median(spike_counts(spike_counts > 0));
            g = length(calciumEvents);

            if ~isfinite(m)
                m = 0;
            end

            if ~isfinite(g)
                g = 0;
            end
            trial_stats(it).m = m;
            trial_stats(it).g = g;
        else

        end
    end
end % iTrial

%%
% figure
% ax(1) = subplot(2,1,1);
% plot(timestamps_ms/1000.0, neuron.trace_raw, 'k-');
% hold on
% stem(spike_timestamps_ms/1000.0, zeros(1, length(spike_timestamps_ms)), 'ro');
% 
% ax(2) = subplot(2,1,2);
% 
% plot(timestamps_ms/1000.0, spike_counts, 'r-', 'linewidth', 4)
% a = axis;
% axis( [a(1), a(2), 0, max([4, max(spike_counts)+1]) ] )
% 
% linkaxes(ax, 'x')

%%
T = struct2table(trial_stats);
S = sortrows(T, [3, 4, 2, 1])
nids = unique(S.neuron_id);

Im = zeros(length(unique(S.trial_id)), length(nids));
Ig = zeros(size(Im));

for iNeuron = 1:length(nids)
   nid = nids(iNeuron);
   s = S(ismember(S.neuron_id, nid), :);
   Im(:, iNeuron) = s.m;
   Ig(:, iNeuron) = s.g;
end

%%
cg = clustergram(Im);
%%
s = sum(Im, 1);
[b,i] = sort(s);
Im = Im(:,i);

% Sort them by context
Ims = zeros(size(Im));
Ims(1:6,:) = Im([1,3,5,7,9,11],:);
Ims(7:12,:) = Im([2,4,6,8,10,12],:);


figure
imagesc(Ims)
