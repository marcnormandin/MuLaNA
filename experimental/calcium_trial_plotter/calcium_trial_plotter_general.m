close all
clear all
clc

subjectName = 'CMG132_CA1';
pipeline_config_filename = fullfile('/work/muzziolab/marc/two_contexts_miniscope', 'pipeline_config.json');
pipeline_config = mulana_json_read(pipeline_config_filename);
experimentParentFolder = fullfile('/work/muzziolab/DATA/Minimice', subjectName, 'recordings/chengs_task_2c');
analysisParentFolder = fullfile('/work/muzziolab/marc/two_contexts_miniscope', subjectName);


% Load the pipeline
pipe = MLCalciumImagingPipeline(pipeline_config, experimentParentFolder, analysisParentFolder);


numSessions = pipe.experiment.numSessions;
parfor iSession = 1:numSessions
    session = pipe.experiment.session{iSession};
    numTrials = session.numTrials;
    
    for iTrial = 1:numTrials
        trial = session.trial{iTrial};
        trialAnalysisFolder = trial.analysisFolder;
        outputFolder = fullfile(trialAnalysisFolder, 'figures');
        if ~exist(outputFolder, 'dir')
            mkdir(outputFolder);
        end

        try
            plot_and_save_placemaps(pipe, trialAnalysisFolder, outputFolder);
        catch e
            errorMsg = getReport(e);
            fprintf('Error processing %s: %s\n', trialAnalysisFolder, errorMsg);
        end
    end % iTrial
end % iSession

fprintf('Done!\n\n');

function plot_and_save_placemaps(pipe, trialResultsFolder, outputFolder)
    %trialResultsFolder = pwd;
    [tr] = ml_cai_trialresult_read( trialResultsFolder );
    tmp = load(fullfile(trialResultsFolder, 'behavcam_roi.mat'));
    tr.behavcam_roi = tmp.behavcam_roi;


    arenaJson = pipe.experiment.info.arena;

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

    movement.x_cm(movement.x_cm > arenaJson.x_length_cm) = arenaJson.x_length_cm;
    movement.y_cm(movement.y_cm > arenaJson.y_length_cm) = arenaJson.y_length_cm;
    movement.x_cm(movement.x_cm < 0) = 0;
    movement.y_cm(movement.y_cm < 0) = 0;
    cm_per_bin = 1.5;
    smoothingKernelGaussianSize_cm = 15;
    smoothingKernelGaussianSigma_cm = 3.0;

    nbinsx = ceil(arenaJson.x_length_cm / cm_per_bin + 1);
    nbinsy = ceil(arenaJson.y_length_cm / cm_per_bin + 1);

    % Construct the kernel. Make sure that it is valid.
    % The kernel sizes must be odd so that they are symmetric
    if mod(smoothingKernelGaussianSize_cm,2) ~= 1
        error('The config value placemaps.smoothingKernelGaussianSize_cm must be odd, but it is %d.', smoothingKernelGaussianSize_cm);
    end
    hsize = ceil(smoothingKernelGaussianSize_cm / cm_per_bin);
    if mod(hsize,2) ~= 1
        hsize = hsize + 1;
    end
    smoothingKernel = fspecial('gaussian', hsize, smoothingKernelGaussianSigma_cm / cm_per_bin);
    smoothingKernel = smoothingKernel ./ max(smoothingKernel(:)); % Isabel wants this like the other



    % Calcium data
    for nid = 1:tr.neuronData.num_neurons
        %nid = 1;
        trace_value = tr.neuronData.neuron(nid).trace_filt;
        trace_ts_ms = tr.scopeVideoData.timestamp_ms;

        pm = MLContinuousPlacemap(movement.x_cm, movement.y_cm, ts_ms, trace_value, trace_ts_ms,...
            'smoothingProtocol', 'SmoothBeforeDivision', ...
            'speed_cm_per_second', movement.speed_cm_per_s, ...
            'boundsx', [0, arenaJson.x_length_cm], ...
            'boundsy', [0, arenaJson.y_length_cm], ...
            'nbinsx', nbinsx, ...
            'nbinsy', nbinsy, ...
            'smoothingKernel', smoothingKernel, ...
            'criteriaDwellTimeSecondsPerBinMinimum', 0, ...
            'criteria_speed_cm_per_second_minimum', 2, ...
            'criteria_speed_cm_per_second_maximum', 50, ...
            'criteria_trace_threshold_minimum', 0.2);

        neuron = MLCaiNeuron( fullfile(trialResultsFolder, 'neuron.hdf5'), nid, trace_ts_ms./1000.0 );
        h = figure('position', get(0, 'Screensize'));
        subplot(2,4,4)
        pm.plot()
        title('Event Map')
        for iOther = 1:numOther
            hold on
            %plot(other_x_cm(iOther), other_y_cm(iOther), 'mo')
            %viscircles([other_x_cm(iOther), other_y_cm(iOther)], 2);
        end
        colorbar
        subplot(2,4,1)
        pm.plot_path_with_spikes()
        title('Path')
        subplot(2,4,2)
        pm.plot_dwellTimeMapSmoothed()
        colorbar
        title('Dwell Time')
        subplot(2,4,3)
        pm.plot_traceMapSmoothed()
        colorbar
        title('Trace Map')
        subplot(2,4,5)
        neuron.plotSpatialFootprint('view', 'full');
        axis equal tight
        title('Spatial Footprint (full)')
        colorbar
        subplot(2,4,6)
        neuron.plotSpatialFootprint('view', 'zoomed');
        colorbar
        axis equal tight
        title('Spatial Footprint (zoomed')
        subplot(2,4,7:8)
        neuron.plotTimeseries();
        xlabel('Time, t [s]')
        grid on
        axis tight
        title(sprintf('Filtered Trace for nid = %d', nid));
        
        filenamePrefix = sprintf('fig_%d', nid);
        fn1 = fullfile(outputFolder, sprintf('%s.png', filenamePrefix));
        fprintf('Saving figure as: %s\n', fn1);
        
        save(fullfile(outputFolder, sprintf('mlcaieventmap_%d', nid)), 'pm', 'nid');
        
        saveas(h, fn1, 'png');
        savefig(h, fullfile(outputFolder, sprintf('%s.fig', filenamePrefix)));
        close(h);
    end % for iNeuron
end % function

