function compute_mcmappy(obj, session, trial)
    experimentDescriptionFilename = fullfile(obj.RecordingsParentFolder, 'experiment_description.json');
    uniform_dt_ms = 10;
    dmax_cm = 0.25;
    maxSpeed_cm_s = 30;
    cm_per_bin = obj.Config.placemaps.cm_per_bin_rect_both_dim;
    cm_per_bin_x = cm_per_bin;
    cm_per_bin_y = cm_per_bin;
    smoothingKernel = obj.SmoothingKernelSymmetric;
    
    traceType = sprintf('trace_%s', obj.Config.placemaps_miniscope.trace_type);

    trialFolder = trial.getAnalysisDirectory();
    neuronFilename = fullfile(trialFolder, 'neuron.hdf5');
    scopeFilename = fullfile(trialFolder, 'scope.hdf5');
    arenaRoiFilename = fullfile(trialFolder, 'behavcam_roi.mat');

    % Load the arena
    arena = ml_arena_initialize_from_file(experimentDescriptionFilename, arenaRoiFilename);

    % Create the bin system
    [boundsx, boundsy] = arena.getCanonicalBounds();
    bs = ml_bs_create(boundsx, boundsy, cm_per_bin_x, cm_per_bin_y);
    
    % Load the mouse movement data
    movement = compute_movement_RAM(obj, trial);
    
    % Load the calcium datasets
    neuronDataset = ml_cai_neuron_h5_read( neuronFilename );
    scopeDataset = ml_cai_scope_h5_read( scopeFilename );

    
    %% Preprocess the data
    pos_x_px = movement.x_px;
    pos_y_px = movement.y_px;

    scopeTimestamps_ms = scopeDataset.timestamp_ms;
    behavTimestamps_ms = movement.timestamps_ms;

    scope_dt_ms = median(diff(scopeTimestamps_ms));
    behav_dt_ms = median(diff(behavTimestamps_ms));

    % Construct a standard set of timestamps
    timestamps_ms = min([min(scopeTimestamps_ms), min(behavTimestamps_ms)]):uniform_dt_ms:max([max(scopeTimestamps_ms), max(behavTimestamps_ms)]);

    % Interpolate the behaviour data to the uniform timestamps
    pos_x_px = interp1(behavTimestamps_ms, pos_x_px, timestamps_ms);
    pos_y_px = interp1(behavTimestamps_ms, pos_y_px, timestamps_ms);
    [pos_x_cm, pos_y_cm] = arena.tranformVidToCanonPoints(pos_x_px, pos_y_px);
    pos_t_s = timestamps_ms/1000.0;
    
    
    % Now smooth the points and estimate the speed
    T_s = uniform_dt_ms/1000.0;

    [smoothed_pos_t_s, smoothed_pos_x_cm, smoothed_pos_y_cm, smoothed_speed_cm_s] = ml_alg_posspeed_estimate_2d_sharifi(pos_t_s, pos_x_cm, pos_y_cm, T_s, dmax_cm, maxSpeed_cm_s);   
%     figure
%     ax(1) = subplot(1,2,1);
%     plot(pos_x_cm, pos_y_cm, 'b-')
%     ax(2) = subplot(1,2,2);
%     plot(smoothed_pos_x_cm, smoothed_pos_y_cm, 'm-')
%     linkaxes(ax, 'xy')
%     sgtitle(sprintf('Trial %d', iTrial))
%     drawnow
    
    % we have new timestamps so use them
    timestamps_ms = smoothed_pos_t_s*1000.0;
    
    % Now filter out points
    validInds = (smoothed_pos_t_s > 0) & (smoothed_speed_cm_s > obj.Config.placemaps.criteria_speed_cm_per_second_minimum); %30*1000;
    
    use_timestamps_ms = smoothed_pos_t_s(validInds)*1000.0;
    use_pos_x_cm = smoothed_pos_x_cm(validInds);
    use_pos_y_cm = smoothed_pos_y_cm(validInds);
    

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
        scopeTrace = interp1(scopeTimestamps_ms, scopeTrace, timestamps_ms);
        
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
        'smoothed_pos_t_s', 'smoothed_pos_x_cm', 'smoothed_pos_y_cm', 'smoothed_speed_cm_s', 'validInds', ...
        'maxSpeed_cm_s', 'dmax_cm', ...
        'traceType', 'numCells');
    
    % Save information data
    save(fullfile(outputFolder, 'climerICS_smoothed.mat'), 'climerICS_smoothed');
    save(fullfile(outputFolder, 'climerICS_unsmoothed.mat'), 'climerICS_unsmoothed');

end % function

function [movement] = compute_movement_RAM(obj, trial)
    trialResultsFolder = trial.getAnalysisDirectory();

    [tr] = ml_cai_trialresult_read( trialResultsFolder );
    tmp = load(fullfile(trialResultsFolder, 'behavcam_roi.mat'));
    tr.behavcam_roi = tmp.behavcam_roi;

    arenaJson = obj.Experiment.getArenaGeometry();

    % Behaviour data
    x_px = tr.behavTrackVid.x';
    y_px = tr.behavTrackVid.y';
    ts_ms = tr.behavTrackVid.timestamps_ms;
    
    % Drop bad points
    in = inpolygon(x_px, y_px, tr.behavcam_roi.inside.j, tr.behavcam_roi.inside.i);
    x_px(~in) = [];
    y_px(~in) = [];
    ts_ms(~in) = [];
    
    movement = mulana_compute_movement(arenaJson, tr.behavcam_roi, x_px, y_px, ts_ms);
end