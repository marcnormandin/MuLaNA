function compute_smoothed_behaviour(obj, session, trial)
    experimentDescriptionFilename = fullfile(obj.RecordingsParentFolder, 'experiment_description.json');
    uniform_dt_ms = 10;
    dmax_cm = 0.25;
    maxSpeed_cm_s = 30;

    trialFolder = trial.getAnalysisDirectory();
    %scopeFilename = fullfile(trialFolder, 'scope.hdf5');
    arenaRoiFilename = fullfile(trialFolder, 'behavcam_roi.mat');

    % Load the arena
    arena = ml_arena_initialize_from_file(experimentDescriptionFilename, arenaRoiFilename);

    % Load the mouse movement data
    [raw_pos_t_ms, raw_pos_x_px, raw_pos_y_px] = compute_movement_RAM(trial);
    
    % Load the calcium datasets
%     scopeDataset = ml_cai_scope_h5_read( scopeFilename );
%     scopeTimestamps_ms = scopeDataset.timestamp_ms;

    % Construct a standard set of timestamps
%     timestamps_ms = min([min(scopeTimestamps_ms), min(raw_pos_t_ms)]):uniform_dt_ms:max([max(scopeTimestamps_ms), max(raw_pos_t_ms)]);
    pos_t_ms = min(raw_pos_t_ms):uniform_dt_ms:max(raw_pos_t_ms);
    
    % Interpolate the behaviour data to the uniform timestamps
    pos_x_px = interp1(raw_pos_t_ms, raw_pos_x_px, pos_t_ms, 'linear', 'extrap');
    pos_y_px = interp1(raw_pos_t_ms, raw_pos_y_px, pos_t_ms, 'linear', 'extrap');
    [pos_x_cm, pos_y_cm] = arena.tranformVidToCanonPoints(pos_x_px, pos_y_px);
    pos_t_s = pos_t_ms/1000.0;
    
    % Now smooth the points and estimate the speed
    T_s = uniform_dt_ms/1000.0;

    [smoothed_pos_t_s, smoothed_pos_x_cm, smoothed_pos_y_cm, smoothed_speed_cm_s] = ml_alg_posspeed_estimate_2d_sharifi(pos_t_s, pos_x_cm, pos_y_cm, T_s, dmax_cm, maxSpeed_cm_s);

    outputFolder = trialFolder;
    outputFilename = fullfile(outputFolder, 'smoothed_behaviour.mat');
    save(outputFilename, ...
        'raw_pos_t_ms', 'raw_pos_x_px', 'raw_pos_y_px', ...
        'pos_t_ms', 'pos_t_s', 'pos_x_px', 'pos_y_px', ...
        'pos_x_cm', 'pos_y_cm', ...
        'smoothed_pos_t_s', 'smoothed_pos_x_cm', 'smoothed_pos_y_cm', 'smoothed_speed_cm_s', ...
        'uniform_dt_ms', 'dmax_cm', 'maxSpeed_cm_s', ...
        'arena');
end % function

% Helper function
function [ts_ms, x_px, y_px] = compute_movement_RAM(trial)
    trialResultsFolder = trial.getAnalysisDirectory();

    [tr] = ml_cai_trialresult_read( trialResultsFolder );
    tmp = load(fullfile(trialResultsFolder, 'behavcam_roi.mat'));
    tr.behavcam_roi = tmp.behavcam_roi;

    %arenaJson = obj.Experiment.getArenaGeometry();

    % Behaviour data
    x_px = tr.behavTrackVid.x';
    y_px = tr.behavTrackVid.y';
    ts_ms = tr.behavTrackVid.timestamps_ms';
    
    % Drop bad points
    in = inpolygon(x_px, y_px, tr.behavcam_roi.inside.j, tr.behavcam_roi.inside.i);
    x_px(~in) = [];
    y_px(~in) = [];
    ts_ms(~in) = [];    
end

