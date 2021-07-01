function mltp_plot_behaviour_averaged_placemaps_contexts(obj, session)

    tfiles_filename_prefixes = session.getTFilesFilenamePrefixes();

    digTypes = ['C', 'G', 'F', 'W']; % don't match '?'
    numDigTypes = length(digTypes);
    numCells = session.getNumTFiles();

    firstDigs = {};
    trialIds = zeros(1, session.getNumTrials());
    contexts = zeros(1, session.getNumTrials());
    for iTrial = 1:session.getNumTrials()
        trial = session.getTrialByOrder(iTrial);
        firstDigs{iTrial} = trial.getDig();
        trialIds(iTrial) = trial.getTrialId();
        contexts(iTrial) = trial.getContextId();
    end

    contexts = sort(unique(contexts));
    numContexts = length(contexts);
    
    for iCell = 1:numCells
        hasMaps = false;
        h = figure();
        tfileName = tfiles_filename_prefixes{iCell};
        
        % Per context
        for iContext = 1:numContexts
            for iDigType = 1:numDigTypes
                dt = digTypes(iDigType);
                ids = strcmpi(firstDigs, dt);
                if ~any(ids)
                    continue;
                end
                %ti = 1:session.getNumTrialsToUse();
                timatch = trialIds(ids);

                pmAveraged = {};
                numAveraged = 0;
                k = numDigTypes*(iContext-1) + iDigType;

                % Average the matching placemaps for the current dig type
                for iMatch = 1:length(timatch)
                    trial = session.getTrial(timatch(iMatch)); % Get the trial by the actual Trial ID
                    
                    % The context must match as well
                    if trial.getContextId() ~= contexts(iContext)
                        continue;
                    end
                    
                    tid = trial.getTrialId();
                    prefix = sprintf('%s_%d', tfileName, tid);
                    fn = fullfile(session.getAnalysisDirectory(), obj.Config.placemaps.outputFolder, ...
                        sprintf('%s_%s', prefix, obj.Config.placemaps.filenameSuffix));
                    if ~isfile(fn)
                        error('The placemap (%s) does not exist.\n', fn);
                    end
                    data = load(fn);
                    pm = data.mltetrodeplacemap;
                    if isempty(pmAveraged)
                        pmAveraged = pm.meanFiringRateMapSmoothed;
                    else
                        pmAveraged = pmAveraged + pm.meanFiringRateMapSmoothed;
                    end
                    hasMaps = true;
                    numAveraged = numAveraged + 1;
                end % iMatches
                
                if numAveraged ~= 0
                    pmAveraged = pmAveraged ./ numAveraged;
                    subplot(numContexts, numDigTypes, k);
                    imagesc(pmAveraged)
                    colormap jet
                    shading interp
                    axis equal tight
                    title(sprintf('Con%d: %s (x%d)', contexts(iContext), dt, numAveraged), 'interpreter', 'none', 'fontsize', 8)
                end
            end % iDig
        end % iContext
        
        % Only save a figure if it actually has data
        if ~hasMaps
            close(h);
            continue;
        end
        
        % Save the figures
        outputFolder = fullfile(session.getAnalysisDirectory(), obj.Config.behaviour_averaged_placemaps.outputFolder);
        if ~exist(outputFolder, 'dir')
            mkdir(outputFolder)
        end
        F = getframe(h);
        fnPrefix = sprintf('%s_behaviour_averaged_placemap', tfileName, session.getName());
        imwrite(F.cdata, fullfile(outputFolder, sprintf('%s.png', fnPrefix)), 'png')
        savefig(h, fullfile(outputFolder, sprintf('%s.fig', fnPrefix)));
        saveas(h, fullfile(outputFolder, sprintf('%s.svg', fnPrefix)), 'svg');
        print('-painters', '-depsc', fullfile(outputFolder,sprintf('%s.eps', fnPrefix)))
        close(h);
    end % iCell
end % function