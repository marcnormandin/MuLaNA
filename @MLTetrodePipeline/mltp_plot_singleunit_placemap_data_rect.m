function mltp_plot_singleunit_placemap_data_rect(obj, session)

    sr = session.sessionRecord;
    ti = sr.getTrialsToProcess();
            
                
    % Get unique ids for the contexts. Dont assume that
    % they are just 1 or 1 and 2.
    uniqueContextIds = sort(unique([ti.context]));
    numContexts = length(uniqueContextIds);

    % Find the number of trials to use for each context
    % since they may not be identical (eg. 4 trials for
    % context 1, but 5 for context 2.
    contextTrialIds = cell(numContexts,1);
    numCols = 0;
    for iContext = 1:length(uniqueContextIds)
        contexts = [ti.context];
        ids = [ti.id];
        contextTrialIds{iContext} = ids(contexts == uniqueContextIds(iContext));
        if length(contextTrialIds{iContext}) > numCols
            numCols = length(contextTrialIds{iContext});
        end
    end


    % Plot each cell's placemap data across the trials "to
    % use" since some crashed and same were redone.
    numCells = session.num_tfiles;
    for iCell = 1:numCells
        fnPrefix = session.tfiles_filename_prefixes{iCell};

        h = figure('Name', sprintf('%s (%s) tfile: %s', sr.getName(), sr.getDate(), fnPrefix), 'Position', get(0,'Screensize'));

        numPlotsPerTrial = 2; % scatter + placemap
        numRows = numContexts * numPlotsPerTrial; % Show spikes and placemap

        for iContext = 1:numContexts
            conTrialIds = contextTrialIds{iContext};
            for iConTrial = 1:length(contextTrialIds{iContext})
                trialId = conTrialIds(iConTrial);
                % Load the data
                fn = fullfile(session.analysisFolder, obj.config.canon_rect_placemaps_folder, ...
                    sprintf('%s_%d_mltetrodeplacemaprect.mat', fnPrefix, trialId));
                tmp = load(fn);

                % Plots contexts as single rows
                digs = ti(trialId).digs{1};
                
                % Only show the digs if it is relevant
                showDigs = true;
                if length(digs) == 1
                    if strcmp(digs, '?') == 1
                        showDigs = false;
                    end
                end
                
                % Not all experiments have digs so only show them on the
                % plot if it is not the default '?'

                % Plot the scatter plot
                k1 = (iContext-1)*numCols*numPlotsPerTrial + iConTrial;
                subplot(numRows, numCols, k1);
                tmp.mltetrodeplacemap.plot_path_with_spikes();
                
                % To show or not to show, that is the question --
                % Shakespere
                if showDigs
                    title(sprintf('T%d S%d C%dT%d\nDigs (%s)', trialId, ti(trialId).sequenceNum, uniqueContextIds(iContext), iConTrial, digs));
                else
                    title(sprintf('T%d S%d C%dT%d', trialId, ti(trialId).sequenceNum, uniqueContextIds(iContext), iConTrial));
                end

                % Plot the placemap
                k2 = (iContext-1)*numCols*numPlotsPerTrial + numCols + iConTrial;
                subplot(numRows, numCols, k2);
                tmp.mltetrodeplacemap.plot();

            end
        end

        % Save the figure
        F = getframe(h);
        outputFolder = fullfile(session.analysisFolder, obj.config.canon_rect_placemaps_folder);
        if ~isfolder(outputFolder)
            mkdir(outputFolder)
        end
        imwrite(F.cdata, fullfile(outputFolder, sprintf('%s_maps.png',fnPrefix)), 'png')
        savefig(h, fullfile(outputFolder, sprintf('%s_maps.fig',fnPrefix)));
        saveas(h, fullfile(outputFolder, sprintf('%s_maps.svg',fnPrefix)), 'svg');
        print('-painters', '-depsc', fullfile(outputFolder, sprintf('%s_maps.eps',fnPrefix)))
        close(h);
    end % for each t-file    
end % function