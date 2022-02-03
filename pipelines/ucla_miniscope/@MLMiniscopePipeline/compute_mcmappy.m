function compute_mcmappy(obj, session, trial)
    % Call this one for the maps using the actual geometry (like a
    % rectangle).
    
    % Load the trace maximums. Isabel said she didn't want this any more.
%     traceMaximumsFilename = fullfile(session.getAnalysisDirectory(), sprintf('%s_trace_%s_maximums.mat', session.getName(), obj.Config.placemaps_miniscope.trace_type));
%     traceMaximumsData = load(traceMaximumsFilename);
%     sessionTraceMaximums = traceMaximumsData.maximumTraceValues;
%     if ~strcmp(traceMaximumsData.traceType, sprintf('trace_%s', obj.Config.placemaps_miniscope.trace_type))
%         error('Session trace maximums doesnt match the placemap trace type to be used.');
%     end
 
    experimentDescriptionFilename = fullfile(obj.RecordingsParentFolder, 'experiment_description.json');

    cm_per_bin = obj.Config.placemaps.cm_per_bin_rect_both_dim;
    cm_per_bin_x = cm_per_bin;
    cm_per_bin_y = cm_per_bin;
    smoothingKernel = obj.SmoothingKernelSymmetric;
    
    traceType = sprintf('trace_%s', obj.Config.placemaps_miniscope.trace_type);

    trialFolder = trial.getAnalysisDirectory();
    neuronFilename = fullfile(trialFolder, 'neuron.hdf5');
    scopeFilename = fullfile(trialFolder, 'scope.hdf5');
    arenaRoiFilename = fullfile(trialFolder, 'behavcam_roi.mat');
    
    % Load the mouse movement data
    behaviourFn = fullfile(trialFolder, 'smoothed_behaviour.mat');
    movement = load(behaviourFn);
    
    % Load the calcium datasets
    neuronDataset = ml_cai_neuron_h5_read( neuronFilename );
    scopeDataset = ml_cai_scope_h5_read( scopeFilename );

%     if traceMaximumsData.numNeurons ~= neuronDataset.num_neurons
%         error('Inconsistent number of neurons used. Trace maximums has %d cells, but neuronDataset has %d\n', traceMaximumsData.numNeurons, neuronDataset.num_neurons);
%     end
    
    % Now filter out points
    validInds = (movement.smoothed_pos_t_s > 0) & (movement.smoothed_speed_cm_s > obj.Config.placemaps.criteria_speed_cm_per_second_minimum);
    
    use_pos_t_ms = movement.smoothed_pos_t_s(validInds)*1000.0;
    use_pos_x_cm = movement.smoothed_pos_x_cm(validInds);
    use_pos_y_cm = movement.smoothed_pos_y_cm(validInds);
    
    % Load the true arena (not shrunk)
    arena = ml_arena_initialize_from_file(experimentDescriptionFilename, arenaRoiFilename);

    % Create the bin system
    [boundsx, boundsy] = arena.getCanonicalBounds();
    bs = ml_bs_create(boundsx, boundsy, cm_per_bin_x, cm_per_bin_y);

    % Compute the maps that are the same for all cells of a given trial
    occupancyMap = ml_bs_occupancy_xy(bs, use_pos_x_cm, use_pos_y_cm);
    occupancyMapSmoothed = imfilter(occupancyMap, smoothingKernel);
    
    averageTimeInterval_s = median(diff(use_pos_t_ms)) / 1000.0; % convert to seconds
    dwellTimeMap = ml_bs_accumulate_xy(bs, use_pos_x_cm, use_pos_y_cm, averageTimeInterval_s);
    dwellTimeMapSmoothed = imfilter(dwellTimeMap, smoothingKernel);
    
    probMap = ml_bs_probxy_xy(bs, use_pos_x_cm, use_pos_y_cm);
    probMapSmoothed = imfilter(probMap, smoothingKernel);
    probMapSmoothed = probMapSmoothed ./ sum(probMapSmoothed, 'all'); % normalize

    eventMaps = zeros(bs.ny, bs.nx, neuronDataset.num_neurons);
    eventMapsSmoothedAfter = zeros(bs.ny, bs.nx, neuronDataset.num_neurons);
    eventMapsSmoothedBefore = zeros(bs.ny, bs.nx, neuronDataset.num_neurons);
    traceMaps = zeros(bs.ny, bs.nx, neuronDataset.num_neurons);
    traceMapsSmoothed = zeros(bs.ny, bs.nx, neuronDataset.num_neurons);
    
    % ILSE maps 
    spikeMaps = zeros(bs.ny, bs.nx, neuronDataset.num_neurons);
    spikeMapsSmoothed = zeros(bs.ny, bs.nx, neuronDataset.num_neurons);
    ilseMaps = zeros(bs.ny, bs.nx, neuronDataset.num_neurons);
    ilseMapsSmoothedBefore = zeros(bs.ny, bs.nx, neuronDataset.num_neurons);
    ilseMapsSmoothedAfter = zeros(bs.ny, bs.nx, neuronDataset.num_neurons);

    rateMapsMean = zeros(bs.ny, bs.nx, neuronDataset.num_neurons);
    rateMapsStd = zeros(bs.ny, bs.nx, neuronDataset.num_neurons);

    
    traceMaximums = zeros(neuronDataset.num_neurons);

    %
    climerICS_smoothed = zeros(neuronDataset.num_neurons,1);
    climerICS_unsmoothed = zeros(neuronDataset.num_neurons,1);

    dt_s = median(diff(movement.smoothed_pos_t_s));

    %% Process each cell
    numCells = neuronDataset.num_neurons;
    for iNeuron = 1:numCells
        scopeTrace = neuronDataset.neuron(iNeuron).(traceType);
        scopeTimestamps_ms = scopeDataset.timestamp_ms;
        
        scopeSpikes = interp1(scopeTimestamps_ms, neuronDataset.neuron(iNeuron).spikes, movement.smoothed_pos_t_s*1000.0, 'linear', 'extrap');
        
        
%         traceScalingMaximum = sessionTraceMaximums(iNeuron);
%         scopeTrace = scopeTrace ./ traceScalingMaximum;
        
        % Interpolate using the same as the behaviour times (before
        % filtering out invalid values).
        scopeTrace = interp1(scopeTimestamps_ms, scopeTrace, movement.smoothed_pos_t_s*1000.0, 'linear', 'extrap');
        
        use_scopeTrace = scopeTrace(validInds);
        use_scopeSpikes = scopeSpikes(validInds);
        
        %traceMaximum = max(use_scopeTrace);
        
        % Set the trace we use to be ZERO if it is below the threshold.
        % Traces will have already been normalized by the maximum.
%         traceThreshold = obj.Config.placemaps_miniscope.criteria_trace_threshold_minimum;
%         use_scopeTrace(use_scopeTrace < traceThreshold) = 0;
        
        
        
        
        % Further filter based on how large the trace is
        % should use the setting: placemaps_miniscope.criteria_trace_threshold_minimum
        
        traceMap = ml_bs_accumulate_xy(bs, use_pos_x_cm, use_pos_y_cm, use_scopeTrace);
        traceMapSmoothed = imfilter(traceMap, smoothingKernel);
        
        spikeMap = ml_bs_accumulate_xy(bs, use_pos_x_cm, use_pos_y_cm, use_scopeSpikes);
        spikeMapSmoothed = imfilter(spikeMap, smoothingKernel);
        
        ilseMap = spikeMap ./ dwellTimeMap;
        ilseMap(~isfinite(ilseMap)) = 0;
        
        ilseMapSmoothedAfter = imfilter(ilseMap, smoothingKernel);
        
        ilseMapSmoothedBefore = spikeMapSmoothed ./ dwellTimeMapSmoothed;
        ilseMapSmoothedBefore(~isfinite(ilseMapSmoothedBefore)) = 0;
        

        eventMap = traceMap ./ dwellTimeMap;
        eventMap(~isfinite(eventMap)) = 0;
        
        eventMapSmoothedAfter = imfilter(eventMap, smoothingKernel);
        
        eventMapSmoothedBefore = traceMapSmoothed ./ dwellTimeMapSmoothed;
        eventMapSmoothedBefore(~isfinite(eventMapSmoothedBefore)) = 0;
        
        climerICS_smoothed(iNeuron) = ml_cai_climer_information_rate_smoothed(probMapSmoothed, traceMapSmoothed);
        climerICS_unsmoothed(iNeuron) = ml_cai_climer_information_rate_smoothed(probMap, traceMap);

        [rateMapMean, rateMapStd] = ml_bs_meanstd_xy(bs, use_pos_x_cm, use_pos_y_cm, use_scopeSpikes ./ dt_s);
        

        % store maps
        traceMaximums(iNeuron) = max(use_scopeTrace);
        traceMaps(:,:,iNeuron) = traceMap;
        traceMapsSmoothed(:,:,iNeuron) = traceMapSmoothed;
        
        spikeMaps(:,:,iNeuron) = spikeMap;
        spikeMapsSmoothed(:,:,iNeuron) = spikeMapSmoothed;
        ilseMaps(:,:,iNeuron) = ilseMap;
        ilseMapsSmoothedBefore(:,:,iNeuron) = ilseMapSmoothedBefore;
        ilseMapsSmoothedAfter(:,:,iNeuron) = ilseMapSmoothedAfter;

        eventMaps(:,:,iNeuron) = eventMap;
        eventMapsSmoothedAfter(:,:,iNeuron) = eventMapSmoothedAfter;
        eventMapsSmoothedBefore(:,:,iNeuron) = eventMapSmoothedBefore;
        
        rateMapsMean(:,:,iNeuron) = rateMapMean;
        rateMapsStd(:,:,iNeuron) = rateMapStd;
    end % iNeuron
    
    % Save map data
    outputFolder = trialFolder;
    outputFilename = fullfile(outputFolder, 'mcmappy.mat');
    save(outputFilename, 'occupancyMap', 'occupancyMapSmoothed', ...
        'dwellTimeMap', 'dwellTimeMapSmoothed', ...
        'probMap','probMapSmoothed',  ...
        'traceMaps', 'traceMapsSmoothed', ...
        'spikeMaps', 'spikeMapsSmoothed', ...
        'ilseMaps', 'ilseMapsSmoothedBefore', 'ilseMapsSmoothedAfter', ...
        'eventMaps', 'eventMapsSmoothedBefore', 'eventMapsSmoothedAfter', ...
        'rateMapsMean', 'rateMapsStd', 'dt_s', ...
        'bs', ...
        'validInds', ...
        'traceType', 'numCells', 'arena', ...
        'traceMaximums');
    
    % Save information data
    save(fullfile(outputFolder, 'climerICS_smoothed.mat'), 'climerICS_smoothed');
    save(fullfile(outputFolder, 'climerICS_unsmoothed.mat'), 'climerICS_unsmoothed');

end % function
