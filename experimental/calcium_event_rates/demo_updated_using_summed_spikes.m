close all
clear all
clc

trialAnalysisFolder = 'R:\chengs_task_2c\data\minimice\feature_rich\CMG162_CA1\analysis_sat\s5\trial_1';
neuronFilename = fullfile(trialAnalysisFolder, 'neuron.hdf5');
scopeFilename = fullfile(trialAnalysisFolder, 'scope.hdf5');

scopeDataset = ml_cai_scope_h5_read(scopeFilename);
neuronDataset = ml_cai_neuron_h5_read(neuronFilename);

scope_timestamps_ms = scopeDataset.timestamp_ms;
% spike_timestamps_ms
% spike_timestamps_ms = 
% [calciumEvents] = ml_cai_neuron_calcium_events(neuron, timestamps_ms, spike_timestamps_ms, MAX_SPIKE_SEPARATION_MS)

MAX_SPIKE_SEPARATION_MS = 250;

figure('position', get(0, 'screensize'))

for iNeuron = 1:20
%iNeuron = randi(neuronDataset.num_neurons);

neuron = neuronDataset.neuron(iNeuron);
dt_ms = median(diff(scopeDataset.timestamp_ms));

spike_value_threshold = prctile(neuron.spikes>0, 25);

spikeIndices = find(neuron.spikes > spike_value_threshold);
spike_values = neuron.spikes(spikeIndices);
spike_timestamps_ms = scopeDataset.timestamp_ms(spikeIndices);

[calciumEvents] = ml_cai_neuron_calcium_spike_groups(spike_timestamps_ms, spike_values, dt_ms, MAX_SPIKE_SEPARATION_MS);
calciumEventMagnitudes = [calciumEvents.summed_spike_value];
minMagnitude = 0.25 * max(calciumEventMagnitudes);

x = [calciumEvents.timestamps_mean_ms];
y = [calciumEvents.summed_spike_value];

subplot(4,5,iNeuron)
plot(scopeDataset.timestamp_ms, neuron.trace_raw, 'k-')
hold on
plot(scopeDataset.timestamp_ms, neuron.trace_filt, 'b-', 'linewidth', 2)
hold on
h = stem(spike_timestamps_ms, spike_values, 'm', 'linewidth', 2);
%set(h,'marker', 'none');
h = stem(x(y>minMagnitude), y(y>minMagnitude), 'g', 'linewidth', 4);
set(h, 'marker', 'none');
axis tight
end


function [calciumEvents] = ml_cai_neuron_calcium_spike_groups(spike_timestamps_ms, spike_values, dt_ms, MAX_SPIKE_SEPARATION_MS)   
   % Form groups of spikes
   spike_groups = ml_util_group_points(spike_timestamps_ms, MAX_SPIKE_SEPARATION_MS);
   numSpikeGroups = length(unique(spike_groups));
   

   % Make a struct array of the calcium events to return
   matFields = {'timestamps_begin_ms', 'timestamps_end_ms', ...
       'timestamps_begin_index', 'timestamps_end_index', ...
       'duration_ms', 'num_spikes', ...
       'summed_spike_value', ...
       'spike_timestamps_ms', 'spike_timestamps_indices', ...
       'spike_values', 'spike_timestamps_mean_ms'
       };
   c = cell(length(matFields),1);
   s = cell2struct(c,matFields);
   calciumEvents = repmat(s, numSpikeGroups, 1);
   
   if isempty(spike_groups)
       calciumEvents = [];
   end

   for iGroup = 1:numSpikeGroups
       % indices of the current spike group
       gsi = find(spike_groups == iGroup);
       
       calciumEvents(iGroup).spike_values = spike_values(gsi); % original used this when using cnmfe spikes => neuron.spikes(gsi);
       
       calciumEvents(iGroup).num_spikes = length(gsi);
       
       calciumEvents(iGroup).spike_timestamps_indices = gsi;
       calciumEvents(iGroup).spike_timestamps_ms = spike_timestamps_ms(gsi);
       
       calciumEvents(iGroup).summed_spike_value = sum(calciumEvents(iGroup).spike_values);
       
       calciumEvents(iGroup).timestamps_begin_index = gsi(1);
       calciumEvents(iGroup).timestamps_begin_ms = spike_timestamps_ms(calciumEvents(iGroup).timestamps_begin_index);
       
       calciumEvents(iGroup).timestamps_end_index = gsi(end);
       calciumEvents(iGroup).timestamps_end_ms = spike_timestamps_ms(calciumEvents(iGroup).timestamps_end_index);
       
       calciumEvents(iGroup).timestamps_mean_ms = mean(calciumEvents(iGroup).spike_timestamps_ms);
       calciumEvents(iGroup).duration_ms = calciumEvents(iGroup).timestamps_end_ms - calciumEvents(iGroup).timestamps_begin_ms;
       if calciumEvents(iGroup).duration_ms == 0
           calciumEvents(iGroup).duration_ms = dt_ms;
       end
       
   end
end % function

