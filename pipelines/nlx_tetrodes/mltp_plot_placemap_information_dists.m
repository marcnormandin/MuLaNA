function mltp_plot_placemap_information_dists(obj, session)
    tFileFilenamePrefixes = session.getTFilesFilenamePrefixes();
    numCells = length(tFileFilenamePrefixes);
    
    for iCell = 1:numCells
        fnPrefix = tFileFilenamePrefixes{iCell};
        
        % We need to know which trials belong to each context.
        cmap = cell(obj.Experiment.getNumContexts(),1);
        for iTrial = 1:session.getNumTrials()
            trial = session.getTrialByOrder(iTrial);
            cmap{trial.getContextId()} = [cmap{trial.getContextId()}, trial.getTrialId()];
        end


        numVerticalPlotsPerTrial = 2;
        numContexts = size(cmap,1);
        p = numContexts * numVerticalPlotsPerTrial;
        q = -1;
        for iContext = 1:numContexts
            if length(cmap{iContext}) > q
                q = length(cmap{iContext});
            end
        end

        h = figure('Name', sprintf('%s (%s) tfile: %s', session.getName(), session.getDate(), fnPrefix), 'Position', get(0,'Screensize'));
        for iContext = 1:numContexts
            kstart = numVerticalPlotsPerTrial * q * (iContext - 1) + 1;
            ct = sort(cmap{iContext}); % trials of the current context
            for k = 1:length(ct)
                trialId = ct(k);
                trial = session.getTrial(trialId);

                if trialId ~= trial.getTrialId()
                    error('Logic error because the trial ids do not match.');
                end
                
                fn = fullfile(session.getAnalysisDirectory(), obj.Config.placemaps.outputFolder, ...
                    sprintf('%s_%d_%s', fnPrefix, trial.getTrialId(), obj.Config.placemaps.filenameSuffix));
                tmp = load(fn);
                pm = tmp.mltetrodeplacemap;

                k1 = kstart + k - 1;
                k2 = kstart + q + k - 1;

                
                subplot(p,q,k1)
                pm.plot_information_rate_distribution([0, 0, 1.0/iContext])
                
                subplot(p,q,k2)
                pm.plot_information_per_spike_distribution([1.0/iContext, 0, 0])

                %title(sprintf('T%d S%d C%d\n%0.2f Hz | %0.2f Hz\n%0.2f b | %0.2f bps', trial.getTrialId(), trial.getSequenceId(), trial.getContextId(), pm.meanFiringRateSmoothed, pm.peakFiringRateSmoothed, ...
                %    pm.informationRate, pm.informationPerSpike))
                
              
            end % iTrial


        end % iContext
        
        % Save the figure
        F = getframe(h);
        outputFolder = fullfile(session.getAnalysisDirectory(), obj.Config.placemaps.outputFolder);
        if ~isfolder(outputFolder)
            mkdir(outputFolder)
        end
        imwrite(F.cdata, fullfile(outputFolder, sprintf('%s_dists.png',fnPrefix)), 'png')
        savefig(h, fullfile(outputFolder, sprintf('%s_dists.fig',fnPrefix)));
        saveas(h, fullfile(outputFolder, sprintf('%s_dists.svg',fnPrefix)), 'svg');
        print('-painters', '-depsc', fullfile(outputFolder, sprintf('%s_dists.eps',fnPrefix)))
        close(h);

    end % iCell

end % function
