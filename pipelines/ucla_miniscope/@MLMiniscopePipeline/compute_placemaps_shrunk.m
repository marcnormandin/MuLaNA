function compute_placemaps_shrunk(obj, session, trial)
    % This shrinks from a rectangle to a square in so that the 90 degree
    % rotations can be performed for the pixel-to-pixel correlations.
    if ~strcmpi(obj.Experiment.getArenaGeometry().shape, 'rectangle')
        fprintf('No need to shrink since shape is a %s.\n', obj.Experiment.getArenaGeometry().shape);
        return;
    end
    
    
    trialResultsFolder = trial.getAnalysisDirectory();
    outputFolder = fullfile(trial.getAnalysisDirectory(), obj.Config.placemaps.outputFolderShrunk);
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end
    
    [tr] = ml_cai_trialresult_read( trialResultsFolder );
    tmp = load(fullfile(trialResultsFolder, 'behavcam_roi.mat'));
    tr.behavcam_roi = tmp.behavcam_roi;

    
    
    % Load the movement so we can get the true speed since that is what
    % should be used for the speed criteria
    tmp = load(fullfile(trialResultsFolder, 'movement.mat'));
    movement = tmp.movement;
    
    % WE NEED TO TRANSFORM THE DATA FROM A RECTANGLE TO A SQUARE
    arenaJson = obj.Experiment.getArenaGeometry();
    shrunk_length_cm = min(arenaJson.x_length_cm, arenaJson.y_length_cm); % should be the smallest dimension (width or length)


    % Do the clipping in the true space
    movement.x_cm(movement.x_cm > arenaJson.x_length_cm) = arenaJson.x_length_cm;
    movement.y_cm(movement.y_cm > arenaJson.y_length_cm) = arenaJson.y_length_cm;
    movement.x_cm(movement.x_cm < 0) = 0;
    movement.y_cm(movement.y_cm < 0) = 0;
    
    % Now map the points from the rectangle (in cm) to the square (in cm)
    % Use a scaling
    movement.x_cm = movement.x_cm / arenaJson.x_length_cm * shrunk_length_cm;
    movement.y_cm = movement.y_cm / arenaJson.y_length_cm * shrunk_length_cm;
    % So now all points are in a square with dimension shrunk_length_cm
    
    cm_per_bin = obj.Config.placemaps.cm_per_bin_square_smallest_dim;
    %smoothingKernelGaussianSize_cm = 15;
    %smoothingKernelGaussianSigma_cm = 3.0;

    nbinsx = ceil(shrunk_length_cm / cm_per_bin + 1);
    nbinsy = ceil(shrunk_length_cm / cm_per_bin + 1);

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
            'boundsx', [0, shrunk_length_cm], ...
            'boundsy', [0, shrunk_length_cm], ...
            'nbinsx', nbinsx, ...
            'nbinsy', nbinsy, ...
            'smoothingKernel', obj.SmoothingKernelRectCompressed, ...
            'criteriaDwellTimeSecondsPerBinMinimum', obj.Config.placemaps.criteria_dwell_time_seconds_per_bin_minimum, ...
            'criteria_speed_cm_per_second_minimum', obj.Config.placemaps.criteria_speed_cm_per_second_minimum, ...
            'criteria_speed_cm_per_second_maximum', obj.Config.placemaps.criteria_speed_cm_per_second_maximum, ...
            'criteria_trace_threshold_minimum', obj.Config.placemaps_miniscope.criteria_trace_threshold_minimum);

                
        save(fullfile(outputFolder, sprintf('%s%d%s', obj.Config.placemaps.filenamePrefix, nid, obj.Config.placemaps.filenameSuffix)), 'pm', 'nid', '-v7.3');
        
%         saveas(h, fn1, 'png');
%         savefig(h, fullfile(outputFolder, sprintf('%s.fig', filenamePrefix)));
%         close(h);
    end % for iNeuron
end % function

