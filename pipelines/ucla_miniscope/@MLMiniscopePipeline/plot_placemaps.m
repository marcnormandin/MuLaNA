function plot_placemaps(obj, session, trial)

    trialResultsFolder = trial.getAnalysisDirectory();
    outputFolder = fullfile(trial.getAnalysisDirectory(), obj.Config.placemaps.outputFolder);
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end
    
    % Calcium data
    for nid = 1:tr.neuronData.num_neurons
        % Load the placemap
        pmFn = fullfile(outputFolder, sprintf('%s%d%s', obj.Config.placemaps.filenamePrefix, nid, obj.Config.placemaps.filenameSuffix));

        tmp = load(pmFn);
        pm = tmp.pm;
        
        neuron = MLCaiNeuron( fullfile(trialResultsFolder, 'neuron.hdf5'), nid, pm.trace_ts_ms./1000.0 );
        h = figure('position', get(0, 'Screensize'));
        subplot(2,4,4)
        pm.plot()
        title('Event Map')
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
                
        saveas(h, fn1, 'png');
        savefig(h, fullfile(outputFolder, sprintf('%s.fig', filenamePrefix)));
        close(h);
    end % for iNeuron
end % function

