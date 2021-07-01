function mltp_plot_placemaps(obj, session)
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
        set(h,'color','w');
        for iContext = 1:numContexts
            kstart = numVerticalPlotsPerTrial * q * (iContext - 1) + 1;
            ct = sort(cmap{iContext}); % trials of the current context
            for k = 1:length(ct)
                trialId = ct(k);
                trial = session.getTrial(trialId);
                
                if trial.getTrialId() ~= trialId
                    error('Logic error because the trial ids do not match.');
                end

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
                    title(sprintf('T%d S%d C%d\nDig: %s', trial.getTrialId(), trial.getSliceId(), trial.getContextId(), trial.getDig()))
                else
                    title(sprintf('T%d S%d C%d', trial.getTrialId(), trial.getSliceId(), trial.getContextId()))
                end
                
                subplot(p,q,k2)
                % Don't use the default since we want to control the style
                % of the plot from the pipleine configuration
                pmrm = pm.meanFiringRateMapSmoothed;

                [nr,nc] = size(pmrm);

                if strcmpi(obj.Config.placemaps.plot_map_shading, 'interp')
                    pcolor( [pmrm, nan(nr,1); nan(1,nc+1)] );
                    shading interp
                        
                    if obj.Config.placemaps.plot_map_unvisited_bins_as_white == 1
                        O = pm.dwellTimeMapTrue;
                        O(O > 0) = 1;
                        O(O < 1) = 0;
                        O = 1 - O;
                        W = ones(size(O,1), size(O,2), 3);
                        
                        hold on
                        hoverlay = imagesc(W);
                        hold off
                        set(hoverlay, 'AlphaData', O);
                    end
                elseif strcmpi(obj.Config.placemaps.plot_map_shading, 'flat')
                    if obj.Config.placemaps.plot_map_unvisited_bins_as_white == 1
                        pmrm(pm.visitedCountMap == 0) = nan;
                    end

                    pcolor( [pmrm, nan(nr,1); nan(1,nc+1)] );
                    shading flat
                else
                    error('config.placemaps.plot_map_shading must be flat or interp.')
                end
                
%                 if obj.Config.placemaps.plot_map_unvisited_bins_as_white == 1
%                     pmrm(pm.visitedCountMap == 0) = nan;
%                 end
%                 pcolor( [pmrm, nan(nr,1); nan(1,nc+1)] );
%                 
%                 if strcmpi(obj.Config.placemaps.plot_map_shading, 'flat')
%                     shading flat;
%                 elseif strcmpi(obj.Config.placemaps.plot_map_shading, 'interp')
%                     shading interp;
%                 end
                
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
        saveas(h, fullfile(outputFolder, sprintf('%s_maps.pdf',fnPrefix)), 'pdf');
        print('-painters', '-depsc', fullfile(outputFolder, sprintf('%s_maps.eps',fnPrefix)))
        close(h);

    end % iCell

end % function
