function mltp_plot_behaviour_averaged_placemaps_contexts(obj, session)

    sr = session.sessionRecord;
    ti = sr.getTrialsToProcess();
    digTypes = ['C', 'G', 'F', 'W']; % don't match '?'
    numDigTypes = length(digTypes);
    numCells = session.num_tfiles;
    %numTrials = sr.getNumTrialsToProcess();
    digs = [ti.digs];
    firstDigs = cell(1,length(digs));
    for i = 1:length(digs)
        firstDigs{i} = digs{i}(1);
    end
    
    contexts = sort(unique([ti.context]));
    numContexts = length(contexts);
    
    for iCell = 1:numCells
        hasMaps = false;
        h = figure();
        tfileName = session.tfiles_filename_prefixes{iCell};
        for iContext = 1:numContexts
            for iDigType = 1:numDigTypes
                dt = digTypes(iDigType);
                ids = strcmpi(firstDigs, dt);
                if ~any(ids)
                    continue;
                end
                timatch = ti(ids);
                k = numDigTypes*(iContext-1) + iDigType;
                pmAveraged = {};
                numAveraged = 0;
                % Average the matching placemaps
                for iMatch = 1:length(timatch)
                    context = timatch(iMatch).context;
                    if context ~= contexts(iContext)
                        continue;
                    end
                    
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
                    hasMaps = true;
                    numAveraged = numAveraged+1;
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
        outputFolder = fullfile(session.analysisFolder, obj.config.behaviour_averaged_placemaps.outputFolder);
        if ~exist(outputFolder, 'dir')
            mkdir(outputFolder)
        end
        F = getframe(h);
        fnPrefix = sprintf('%s_behaviour_averaged_placemap_contexts', tfileName, session.name);
        imwrite(F.cdata, fullfile(outputFolder, sprintf('%s.png', fnPrefix)), 'png')
        savefig(h, fullfile(outputFolder, sprintf('%s.fig', fnPrefix)));
        saveas(h, fullfile(outputFolder, sprintf('%s.svg', fnPrefix)), 'svg');
        print('-painters', '-depsc', fullfile(outputFolder,sprintf('%s.eps', fnPrefix)))
        close(h);
    end % iCell
end % function