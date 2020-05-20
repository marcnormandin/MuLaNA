close all
clear all
clc

sessionFolders = {'s1', 's2', 's3'};
for iFolder = 1:length(sessionFolders)
    sessionFolder = fullfile(pwd,  sessionFolders{iFolder});
    subFolders = mulana_util_get_subfolders(sessionFolder);
    
    trialFolders = {};
    for iT = 1:length(subFolders)
        folder = subFolders{iT};
        if strcmp(subFolders{iT}(1), 'H')
            trialFolders{end+1} = folder;
        end
    end
    
    for iT = 1:length(trialFolders)
        trialResultsFolder =fullfile(sessionFolder, trialFolders{iT});
        outputFolder = fullfile(trialResultsFolder, 'figures');
        if ~exist(outputFolder, 'dir')
            mkdir(outputFolder);
        end

        try
            plot_and_save_placemaps(trialResultsFolder, outputFolder);
        catch e
            errorMsg = getReport(e);
            fprintf('Error processing %s: %s\n', trialResultsFolder, errorMsg);
        end
    end % iTrial
end % iSession

fprintf('Done!\n\n');

function plot_and_save_placemaps(trialResultsFolder, outputFolder)
    %trialResultsFolder = pwd;
    [tr] = ml_cai_trialresult_read( trialResultsFolder );
    tmp = load(fullfile(trialResultsFolder, 'behavcam_roi.mat'));
    tr.behavcam_roi = tmp.behavcam_roi;


    arenaJson = {};
    arenaJson.shape = 'rectangle';
    arenaJson.x_length_cm = 20;
    arenaJson.y_length_cm = 30;

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
    cm_per_bin = 1;
    smoothingKernelGaussianSize_cm = 15;
    smoothingKernelGaussianSigma_cm = 3.0;

    nbinsx = ceil(arenaJson.x_length_cm / cm_per_bin + 1);
    nbinsy = ceil(arenaJson.y_length_cm / cm_per_bin + 1);

    % Construct the kernel. Make sure that it is valid.
    % The kernel sizes must be odd so that they are symmetric
    if mod(smoothingKernelGaussianSize_cm,2) ~= 1
        error('The config value placemaps.smoothingKernelGaussianSize_cm must be odd, but it is %d.', smoothingKernelGaussianSize_cm);
    end
    smoothingKernel = fspecial('gaussian', smoothingKernelGaussianSize_cm / cm_per_bin, smoothingKernelGaussianSigma_cm / cm_per_bin);
    smoothingKernel = smoothingKernel ./ max(smoothingKernel(:)); % Isabel wants this like the other



    % Calcium data
    for nid = 1:tr.neuronData.num_neurons
        %nid = 1;
        trace_value = tr.neuronData.neuron(nid).trace_filt;
        trace_ts_ms = tr.scopeVideoData.timestamp_ms;

        pm = MLContinuousPlacemap(movement.x_cm, movement.y_cm, ts_ms, trace_value, trace_ts_ms,...
            'smoothingProtocol', 'SmoothAfterDivision', ...
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
        % subplot(2,4,5)
        % neuron.plotSpatialFootprint('view', 'full');
        % axis equal tight
        % title('Spatial Footprint (full)')
        % colorbar
        % subplot(2,4,6)
        % neuron.plotSpatialFootprint('view', 'zoomed');
        % colorbar
        % axis equal tight
        % title('Spatial Footprint (zoomed')
        subplot(2,4,5:8)
        neuron.plotTimeseries();
        xlabel('Time, t [s]')
        grid on
        axis tight
        title(sprintf('Filtered Trace for nid = %d', nid));
        
        filenamePrefix = sprintf('fig_%d', nid);
        fn1 = fullfile(outputFolder, sprintf('%s.png', filenamePrefix));
        fprintf('Saving figure as: %s\n', fn1);
        
        saveas(h, fn1, 'png');
        savefig(h, fullfile(outputFolder, sprintf('%s.fig', filenamePrefix)));
        close(h);
    end % for iNeuron
end % function

