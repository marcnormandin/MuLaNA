function compute_mcmappy(obj, session, trial)
    % Call this one for the maps using the actual geometry (like a
    % rectangle).
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
    probMap = ml_bs_probxy_xy(bs, use_pos_x_cm, use_pos_y_cm);
    probMapSmoothed = imfilter(probMap, smoothingKernel);
    probMapSmoothed = probMapSmoothed ./ sum(probMapSmoothed, 'all'); % normalize

    eventMaps = zeros(bs.ny, bs.nx, neuronDataset.num_neurons);
    eventMapsSmoothedAfter = zeros(bs.ny, bs.nx, neuronDataset.num_neurons);
    eventMapsSmoothedBefore = zeros(bs.ny, bs.nx, neuronDataset.num_neurons);
    traceMaps = zeros(bs.ny, bs.nx, neuronDataset.num_neurons);
    traceMapsSmoothed = zeros(bs.ny, bs.nx, neuronDataset.num_neurons);

    %
    climerICS_smoothed = zeros(neuronDataset.num_neurons,1);
    climerICS_unsmoothed = zeros(neuronDataset.num_neurons,1);


    %% Process each cell
    numCells = neuronDataset.num_neurons;
    for iNeuron = 1:numCells
        scopeTrace = neuronDataset.neuron(iNeuron).(traceType);
        scopeTimestamps_ms = scopeDataset.timestamp_ms;
        
        % Interpolate using the same as the behaviour times (before
        % filtering out invalid values).
        scopeTrace = interp1(scopeTimestamps_ms, scopeTrace, movement.smoothed_pos_t_s*1000.0, 'linear', 'extrap');
        
        use_scopeTrace = scopeTrace(validInds);
        
        % Further filter based on how large the trace is
        % should use the setting: placemaps_miniscope.criteria_trace_threshold_minimum
        
        traceMap = ml_bs_accumulate_xy(bs, use_pos_x_cm, use_pos_y_cm, use_scopeTrace);
        traceMapSmoothed = imfilter(traceMap, smoothingKernel);

        eventMap = traceMap ./ probMap;
        eventMap(~isfinite(eventMap)) = 0;
        
        eventMapSmoothedAfter = imfilter(eventMap, smoothingKernel);
        
        eventMapSmoothedBefore = traceMapSmoothed ./ probMapSmoothed;
        eventMapSmoothedBefore(~isfinite(eventMapSmoothedBefore)) = 0;
        
        climerICS_smoothed(iNeuron) = ml_cai_climer_information_rate_smoothed(probMapSmoothed, traceMapSmoothed);
        climerICS_unsmoothed(iNeuron) = ml_cai_climer_information_rate_smoothed(probMap, traceMap);


        % store
        traceMaps(:,:,iNeuron) = traceMap;
        traceMapsSmoothed(:,:,iNeuron) = traceMapSmoothed;
        eventMaps(:,:,iNeuron) = eventMap;
        eventMapsSmoothedAfter(:,:,iNeuron) = eventMapSmoothedAfter;
        eventMapsSmoothedBefore(:,:,iNeuron) = eventMapSmoothedBefore;
    end % iNeuron
    
    % Save map data
    outputFolder = trialFolder;
    outputFilename = fullfile(outputFolder, 'mcmappy.mat');
    save(outputFilename, 'occupancyMap', 'occupancyMapSmoothed', ...
        'probMap','probMapSmoothed',  ...
        'traceMaps', 'traceMapsSmoothed', ...
        'eventMaps', 'eventMapsSmoothedBefore', 'eventMapsSmoothedAfter', ...
        'bs', ...
        'validInds', ...
        'traceType', 'numCells', 'arena');
    
    % Save information data
    save(fullfile(outputFolder, 'climerICS_smoothed.mat'), 'climerICS_smoothed');
    save(fullfile(outputFolder, 'climerICS_unsmoothed.mat'), 'climerICS_unsmoothed');

end % function
