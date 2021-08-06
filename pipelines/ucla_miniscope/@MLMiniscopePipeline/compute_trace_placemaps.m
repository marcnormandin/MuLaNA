function compute_trace_placemaps(obj, session, trial)

    trialResultsFolder = trial.getAnalysisDirectory();
    outputFolder = fullfile(trial.getAnalysisDirectory(), obj.Config.placemaps.outputFolder);
    
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end
    
    % Remove any pre-existing placemaps
    %delete(fullfile(outputFolder, sprintf('%s*%s', obj.Config.placemaps.filenamePrefix, obj.Config.placemaps.filenameSuffix)));
    
    %trialResultsFolder = pwd;
    [tr] = ml_cai_trialresult_read( trialResultsFolder );
    tmp = load(fullfile(trialResultsFolder, 'behavcam_roi.mat'));
    tr.behavcam_roi = tmp.behavcam_roi;


    arenaJson = obj.Experiment.getArenaGeometry();

    [other_x_cm, other_y_cm] = mulana_transform_other_roi(arenaJson, tr.behavcam_roi);
    numOther = length(other_x_cm);

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

    cm_per_bin = obj.Config.placemaps.cm_per_bin_rect_both_dim;
    
    if strcmpi( arenaJson.shape, 'rectangle' )
        movement.x_cm(movement.x_cm > arenaJson.x_length_cm) = arenaJson.x_length_cm;
        movement.y_cm(movement.y_cm > arenaJson.y_length_cm) = arenaJson.y_length_cm;
        movement.x_cm(movement.x_cm < 0) = 0;
        movement.y_cm(movement.y_cm < 0) = 0;
            
        nbinsx = ceil(arenaJson.x_length_cm / cm_per_bin + 1);
        nbinsy = ceil(arenaJson.y_length_cm / cm_per_bin + 1);
        
        maxx_cm = arenaJson.x_length_cm;
        maxy_cm = arenaJson.y_length_cm;
    elseif strcmpi( arenaJson.shape, 'square' )
        movement.x_cm(movement.x_cm > arenaJson.length_cm) = arenaJson.length_cm;
        movement.y_cm(movement.y_cm > arenaJson.length_cm) = arenaJson.length_cm;
        movement.x_cm(movement.x_cm < 0) = 0;
        movement.y_cm(movement.y_cm < 0) = 0;
        
        nbinsx = ceil(arenaJson.length_cm / cm_per_bin + 1);
        nbinsy = nbinsx;
        
        maxx_cm = arenaJson.length_cm;
        maxy_cm = maxx_cm;
    elseif strcmpi (arenaJson.shape, 'circle' )
        movement.x_cm(movement.x_cm > arenaJson.diameter_cm) = arenaJson.diameter_cm;
        movement.y_cm(movement.y_cm > arenaJson.diameter_cm) = arenaJson.diameter_cm;
        movement.x_cm(movement.x_cm < 0) = 0;
        movement.y_cm(movement.y_cm < 0) = 0;
        
        nbinsx = ceil(arenaJson.diameter_cm / cm_per_bin + 1);
        nbinsy = ceil(arenaJson.diameter_cm / cm_per_bin + 1);
        
        maxx_cm = arenaJson.diameter_cm;
        maxy_cm = maxx_cm;
    else
        error('Invalid arena shape. Must be rectangle, square, or circle.');
    end
    
    % save the movement data
    save(fullfile(trial.getAnalysisDirectory(), 'movement.mat'), 'movement', '-v7.3');
    


    % Construct the kernel. Make sure that it is valid.
    % The kernel sizes must be odd so that they are symmetric
    %if mod(smoothingKernelGaussianSize_cm,2) ~= 1
    %    error('The config value placemaps.smoothingKernelGaussianSize_cm must be odd, but it is %d.', smoothingKernelGaussianSize_cm);
    %end
    %hsize = ceil(smoothingKernelGaussianSize_cm / cm_per_bin);
    %if mod(hsize,2) ~= 1
    %    hsize = hsize + 1;
    %end
    %smoothingKernel = fspecial('gaussian', hsize, smoothingKernelGaussianSigma_cm / cm_per_bin);
    %smoothingKernel = smoothingKernel ./ max(smoothingKernel(:)); % Isabel wants this like the other

   

    % Calcium data
    for nid = 1:tr.neuronData.num_neurons
        %nid = 1;
        if strcmp(obj.Config.placemaps_miniscope.trace_type, "raw") == 1
            trace_value = tr.neuronData.neuron(nid).trace_raw;
        elseif strcmp(obj.Config.placemaps_miniscope.trace_type, "filtered") == 1
            trace_value = tr.neuronData.neuron(nid).trace_filt;
        else
            error('Invalid config value for placemaps_miniscope.trace_type. Must be raw or filtered.');
        end

        trace_ts_ms = tr.scopeVideoData.timestamp_ms;
        

        pm = MLContinuousPlacemap(movement.x_cm, movement.y_cm, movement.timestamps_ms, trace_value, trace_ts_ms,...
            'smoothingProtocol', obj.Config.placemaps.smoothingProtocol, ...
            'speed_cm_per_second', movement.speed_smoothed_cm_per_s, ...
            'boundsx', [0, maxx_cm], ...
            'boundsy', [0, maxy_cm], ...
            'nbinsx', nbinsx, ...
            'nbinsy', nbinsy, ...
            'smoothingKernel', obj.SmoothingKernelSymmetric, ...
            'criteriaDwellTimeSecondsPerBinMinimum', obj.Config.placemaps.criteria_dwell_time_seconds_per_bin_minimum, ...
            'criteria_speed_cm_per_second_minimum', obj.Config.placemaps.criteria_speed_cm_per_second_minimum, ...
            'criteria_speed_cm_per_second_maximum', obj.Config.placemaps.criteria_speed_cm_per_second_maximum, ...
            'criteria_trace_threshold_minimum', obj.Config.placemaps_miniscope.criteria_trace_threshold_minimum);

%         pm = MLContinuousPlacemap(movement.x_cm, movement.y_cm, movement.timestamps_ms, trace_value, trace_ts_ms,...
%             'smoothingProtocol', obj.Config.placemaps.smoothingProtocol, ...
%             'speed_cm_per_second', movement.speed_smoothed_cm_per_s, ...
%             'boundsx', [0, arenaJson.x_length_cm], ...
%             'boundsy', [0, arenaJson.y_length_cm], ...
%             'nbinsx', nbinsx, ...
%             'nbinsy', nbinsy, ...
%             'smoothingKernel', obj.SmoothingKernel, ...
%             'criteriaDwellTimeSecondsPerBinMinimum', obj.Config.placemaps.criteria_dwell_time_seconds_per_bin_minimum, ...
%             'criteria_speed_cm_per_second_minimum', obj.Config.placemaps.criteria_speed_cm_per_second_minimum, ...
%             'criteria_speed_cm_per_second_maximum', obj.Config.placemaps.criteria_speed_cm_per_second_maximum, ...
%             'criteria_trace_threshold_minimum', obj.Config.placemaps_miniscope.criteria_trace_threshold_minimum);

        
        save(fullfile(outputFolder, sprintf('%s%d%s', obj.Config.placemaps.filenamePrefix, nid, obj.Config.placemaps.filenameSuffix)), 'pm', 'nid', '-v7.3');
        
%         fn1 = fullfile(outputFolder, sprintf('%s%d%s', obj.Config.placemaps.filenamePrefix, nid, '.png'));
%         fprintf('Saving figure as: %s\n', fn1);
%         saveas(h, fn1, 'png');
        %savefig(h, fullfile(outputFolder, sprintf('%s.fig', filenamePrefix)));
%         close(h);
    end % for iNeuron
end % function