function [calciumEvents] = ml_cai_neuron_calcium_events(neuron, timestamps_ms, spike_timestamps_ms, MAX_SPIKE_SEPARATION_MS)
   %SPIKE_THRESHOLD = 0;
   %MAX_SPIKE_SEPARATION_MS = 100;
   

  
%    % Only use spikes whose values exceed the given threshold
%    si = find(neuron.spikes > SPIKE_THRESHOLD);
%    
%    % Timestamps of all the spikes that passed the threshold
%    spike_timestamps_ms = timestamps_ms(si);
   numSpikes = length(spike_timestamps_ms);
   si = nan(1,numSpikes);
   for i = 1:numSpikes
       k = find(timestamps_ms > spike_timestamps_ms(i), 1, 'first');
       if ~isempty(k)
           si(i) = k;
       else
           si(i) = nan;
       end
   end
   spike_timestamps_ms(isnan(si)) = [];
   si(isnan(si)) = [];

   numSpikes = length(si);

   % Form groups of spikes
   spike_groups = ml_util_group_points(spike_timestamps_ms, MAX_SPIKE_SEPARATION_MS);
   numSpikeGroups = length(unique(spike_groups));


   % Make a struct array of the calcium events to return
   matFields = {'timestamps_begin_ms', 'timestamps_end_ms', ...
       'timestamps_begin_index', 'timestamps_end_index', ...
       'integrated_trace_filt', 'integrated_trace_raw', ...
       'duration_ms', 'num_spikes', ...
       'spike_timestamps_ms', 'spike_timestamps_indices', ...
       'spike_values', 'spike_timestamps_mean_ms'
       };
   c = cell(length(matFields),1);
   s = cell2struct(c,matFields);
   calciumEvents = repmat(s, numSpikeGroups, 1);
   
   if isempty(si)
       calciumEvents = [];
   end

   for iGroup = 1:numSpikeGroups
       % indices of the current spike group
       gsi = si(spike_groups == iGroup);
       
       calciumEvents(iGroup).spike_values = ones(1, length(gsi)); % original used this when using cnmfe spikes => neuron.spikes(gsi);
       
       calciumEvents(iGroup).num_spikes = length(gsi);
       
       calciumEvents(iGroup).spike_timestamps_indices = gsi;
       calciumEvents(iGroup).spike_timestamps_ms = timestamps_ms(gsi);
       
       calciumEvents(iGroup).timestamps_begin_index = gsi(1);
       calciumEvents(iGroup).timestamps_begin_ms = timestamps_ms(calciumEvents(iGroup).timestamps_begin_index);
       
       calciumEvents(iGroup).timestamps_end_index = gsi(end);
       calciumEvents(iGroup).timestamps_end_ms = timestamps_ms(calciumEvents(iGroup).timestamps_end_index);
       
       calciumEvents(iGroup).timestamps_mean_ms = mean(calciumEvents(iGroup).spike_timestamps_ms);
       
       calciumEvents(iGroup).duration_ms = calciumEvents(iGroup).timestamps_end_ms - calciumEvents(iGroup).timestamps_begin_ms;
       
       if length(gsi) > 1
           % Only subtract the start if there is more than one value
           dt = calciumEvents(iGroup).timestamps_end_ms - calciumEvents(iGroup).timestamps_begin_ms;
       else
           % Handle the case of a single spike.
           if calciumEvents(iGroup).timestamps_begin_index > 1
               dt = calciumEvents(iGroup).timestamps_begin_ms - timestamps_ms(calciumEvents(iGroup).timestamps_begin_index-1);
           else
               % end and beginning index are the same
               dt = timstamps_ms(calciumEvents(iGroup).timestamp_begin_index+1) - calciumEvents(iGroup).timestamp_begin_ms;
           end
       end
       
       % integrated (basic) filtered trace
       a = neuron.trace_filt(gsi);
       if length(a) > 1
           % Only subtract the start if there is more than one value
           calciumEvents(iGroup).integrated_trace_filt = sum(a) - min(a, [], 'all')*calciumEvents(iGroup).num_spikes;
           calciumEvents(iGroup).integrated_trace_filt = calciumEvents(iGroup).integrated_trace_filt ./ dt*1000.0;
       else
           calciumEvents(iGroup).integrated_trace_filt = a ./ dt;
       end
       
       % integrated (basic) raw trace
       a = neuron.trace_raw(gsi);
       if length(a) > 1
           % Only subtract the start if there is more than one value
           calciumEvents(iGroup).integrated_trace_raw = sum(a) - min(a, [], 'all')*calciumEvents(iGroup).num_spikes;
           calciumEvents(iGroup).integrated_trace_raw = calciumEvents(iGroup).integrated_trace_raw ./ dt*1000.0;
       else
           calciumEvents(iGroup).integrated_trace_raw = a ./ dt;
       end
   end
end % function
