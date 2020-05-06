function mltp_plot_behaviour_averaged_placemaps(obj, session)

    sr = session.sessionRecord;
    ti = sr.getTrialsToProcess();
    digTypes = ['C', 'G', 'F', 'W'];
    numDigTypes = length(digTypes);
    numCells = session.num_tfiles;
    %numTrials = sr.getNumTrialsToProcess();
    digs = [ti.digs];
    firstDigs = cell(1,length(digs));
    for i = 1:length(digs)
        firstDigs{i} = digs{i}(1);
    end

    for iCell = 1:numCells
        h = figure();
        tfileName = session.tfiles_filename_prefixes{iCell};
        for iDigType = 1:numDigTypes
            dt = digTypes(iDigType);
            ids = strcmpi(firstDigs, dt);
            if ~any(ids)
                continue;
            end
            timatch = ti(ids);

            pmAveraged = {};

            % Average the matching placemaps
            for iMatch = 1:length(timatch)
                tid = timatch(iMatch).id;
                prefix = sprintf('%s_%d', tfileName, tid);
                fn = fullfile(session.analysisFolder, obj.config.placemaps.outputFolder, ...
                    sprintf('%s_%s', prefix, obj.config.placemaps.filenameSuffix));
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
        if isempty(pmAveraged)
            close(h);
            continue;
        end
        
        % Save the figures
        outputFolder = fullfile(session.analysisFolder, obj.config.behaviour_averaged_placemaps.outputFolder);
        if ~exist(outputFolder, 'dir')
            mkdir(outputFolder)
        end
        F = getframe(h);
        fnPrefix = sprintf('%s_behaviour_averaged_placemap', tfileName, session.name);
        imwrite(F.cdata, fullfile(outputFolder, sprintf('%s.png', fnPrefix)), 'png')
        savefig(h, fullfile(outputFolder, sprintf('%s.fig', fnPrefix)));
        saveas(h, fullfile(outputFolder, sprintf('%s.svg', fnPrefix)), 'svg');
        print('-painters', '-depsc', fullfile(outputFolder,sprintf('%s.eps', fnPrefix)))
        close(h);
    end % iCell
end % function