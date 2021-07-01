function mltp_plot_behaviour_averaged_placemaps(obj, session)

    tfiles_filename_prefixes = session.getTFilesFilenamePrefixes();

    digTypes = ['C', 'G', 'F', 'W']; % don't match '?'
    numDigTypes = length(digTypes);
    numCells = session.getNumTFiles();

    firstDigs = {};
    trialIds = zeros(1, session.getNumTrials());
    for iTrial = 1:session.getNumTrials()
        trial = session.getTrialByOrder(iTrial);
        firstDigs{end+1} = trial.getDig();
        trialIds(iTrial) = trial.getTrialId();
    end
    %trialIds = session.getTrialIds();

    for iCell = 1:numCells
        hasMaps = false;
        h = figure();
        tfileName = tfiles_filename_prefixes{iCell};
        
        for iDigType = 1:numDigTypes
            dt = digTypes(iDigType);
            ids = strcmpi(firstDigs, dt);
            if ~any(ids)
                continue;
            end
            
            timatch = trialIds(ids);

            pmAveraged = {};

            % Average the matching placemaps for the current dig type
            for iMatch = 1:length(timatch)
                trial = session.getTrial(timatch(iMatch)); % Return by actual Trial ID
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
            end % iMatches
            pmAveraged = pmAveraged ./ length(timatch);

            subplot(1, numDigTypes, iDigType);
            imagesc(pmAveraged)
            colormap jet
            shading interp
            axis equal tight
            title(sprintf('%s : %s (x%d)', tfileName, dt, length(timatch)), 'interpreter', 'none')
        end % iDig
        
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