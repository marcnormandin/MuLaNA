function mltp_plot_placemaps(obj, session)
    tFileFilenamePrefixes = session.getTFilesFilenamePrefixes();
    numCells = length(tFileFilenamePrefixes);
    
    for iCell = 1:numCells
        fnPrefix = tFileFilenamePrefixes{iCell};
        
        % We need to know which trials belong to each context.
        cmap = cell(obj.Experiment.getNumContexts(),1);
        for iTrialToUse = 1:session.getNumTrialsToUse()
            trial = session.getTrialToUse(iTrialToUse);
            cmap{trial.getContextId()} = [cmap{trial.getContextId()}, iTrialToUse];
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
        set(h,'color','w');
        for iContext = 1:numContexts
            kstart = numVerticalPlotsPerTrial * q * (iContext - 1) + 1;
            ct = cmap{iContext}; % trials of the current context
            for k = 1:length(ct)
                iTrialToUse = ct(k);
                trial = session.getTrialToUse(iTrialToUse);

%                 fn = fullfile(trial.getAnalysisDirectory(), pipe.Config.placemaps.outputFolder, sprintf('pm_%d.mat', iCell));
%                 tmp = load(fn);
%                 pm = tmp.pm;
                % Load the data
                fn = fullfile(session.getAnalysisDirectory(), obj.Config.placemaps.outputFolder, ...
                    sprintf('%s_%d_%s', fnPrefix, trial.getTrialId(), obj.Config.placemaps.filenameSuffix));
                tmp = load(fn);
                pm = tmp.mltetrodeplacemap;

                k1 = kstart + k - 1;
                k2 = kstart + q + k - 1;
                
                % To show or not to show
                % Plots contexts as single rows
                dig = trial.getDig();
                
                % Only show the digs if it is relevant
                showDigs = true;
                if length(dig) == 1 && strcmp(dig, '?') == 1
                    showDigs = false;
                end

                subplot(p,q,k1)
                pm.plot_path_with_spikes()
                if showDigs
                    title(sprintf('T%d S%d C%d\nDig: %s', trial.getTrialId(), trial.getSequenceId(), trial.getContextId(), trial.getDig()))
                else
                    title(sprintf('T%d S%d C%d', trial.getTrialId(), trial.getSequenceId(), trial.getContextId()))
                end
                
                subplot(p,q,k2)
                % Don't use the default since we want to control the style
                % of the plot from the pipleine configuration
                pmrm = pm.meanFiringRateMapSmoothed;

                [nr,nc] = size(pmrm);

                
                if obj.Config.placemaps.plot_map_unvisited_bins_as_white == 1
                    pmrm(pm.visitedCountMap == 0) = nan;
                end
                pcolor( [pmrm, nan(nr,1); nan(1,nc+1)] );
                
                if strcmpi(obj.Config.placemaps.plot_map_shading, 'flat')
                    shading flat;
                elseif strcmpi(obj.Config.placemaps.plot_map_shading, 'interp')
                    shading interp;
                end
                
                set(gca, 'ydir', 'reverse');

                axis image off
                colormap jet 
        
                %title(sprintf('T%d S%d C%d', trial.getTrialId(), trial.getSequenceId(), trial.getContextId()))
                title(sprintf('%0.2f Hz | %0.2f Hz\n%0.2f b | %0.2f bps\nunsmoothed %0.2f Hz | %0.2f Hz', ...
                    pm.meanFiringRateSmoothed, pm.peakFiringRateSmoothed, ...
                    pm.informationRate, pm.informationPerSpike, ...
                    pm.meanFiringRate, pm.peakFiringRate));
            end % iTrial


        end % iContext
        
        % Save the figure
        F = getframe(h);
        outputFolder = fullfile(session.getAnalysisDirectory(), obj.Config.placemaps.outputFolder);
        if ~isfolder(outputFolder)
            mkdir(outputFolder)
        end
        imwrite(F.cdata, fullfile(outputFolder, sprintf('%s_maps.png',fnPrefix)), 'png')
        savefig(h, fullfile(outputFolder, sprintf('%s_maps.fig',fnPrefix)));
        saveas(h, fullfile(outputFolder, sprintf('%s_maps.svg',fnPrefix)), 'svg');
        print('-painters', '-depsc', fullfile(outputFolder, sprintf('%s_maps.eps',fnPrefix)))
        close(h);

    end % iCell

end % function
