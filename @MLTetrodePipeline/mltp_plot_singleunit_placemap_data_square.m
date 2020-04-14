function mltp_plot_singleunit_placemap_data_square(obj, session)
    % Get unique ids for the contexts. Dont assume that
    % they are just 1 or 1 and 2.
    uniqueContextIds = sort(unique(session.record.trial_info.contexts));
    numContexts = length(uniqueContextIds); % or use session.num_contexts;

    % Find the number of trials to use for each context
    % since they may not be identical (eg. 4 trials for
    % context 1, but 5 for context 2.
    contextTrialIds = cell(numContexts,1);
    numCols = 0;
    for iContext = 1:length(uniqueContextIds)
        contextId = uniqueContextIds(iContext);
        fprintf('Processing information for context %d\n', contextId);

        for iTrial = 1:session.num_trials_recorded
            if session.record.trial_info.contexts(iTrial) == contextId && session.record.trial_info.use(iTrial) == 1
                contextTrialIds{iContext} = [contextTrialIds{iContext} iTrial];
            end
        end
        if length(contextTrialIds(iContext)) > numCols
            numCols = length(contextTrialIds{iContext});
        end

    end


    % Plot each cell's placemap data across the trials "to
    % use" since some crashed and same were redone.
    numCells = session.num_tfiles;
    for iCell = 1:numCells
        fnPrefix = session.tfiles_filename_prefixes{iCell};

%                       arenaColours = obj.config.session_orientation_plot.trial_pos_colours;

        h = figure('Name', sprintf('%s (%s) tfile: %s', session.record.session_info.name, session.record.session_info.date, fnPrefix), 'Position', get(0,'Screensize'));

        numPlotsPerTrial = 2;
        numRows = session.num_contexts * numPlotsPerTrial; % Show spikes and placemap

        for iContext = 1:numContexts
            conTrialIds = contextTrialIds{iContext};
            for iConTrial = 1:length(contextTrialIds{iContext})
                iTrial = conTrialIds(iConTrial);
                % Load the data
                fn = fullfile(session.analysisFolder, obj.config.canon_square_placemaps_folder, ...
                    sprintf('%s_%d_mltetrodeplacemapsquare.mat', fnPrefix, iTrial));
                tmp = load(fn);

                % Plots contexts as single rows
                dig = session.record.trial_info.digs{iTrial};

                % Plot the scatter plot
                k1 = (iContext-1)*numCols*numPlotsPerTrial + iConTrial;
                subplot(numRows, numCols, k1);
                tmp.mltetrodeplacemap.plot_path_with_spikes();
                title(sprintf('T%d C%dT%d\nDig (%s)', iTrial, uniqueContextIds(iContext), iConTrial, dig));

                % Plot the placemap
                k2 = (iContext-1)*numCols*numPlotsPerTrial + numCols + iConTrial;
                subplot(numRows, numCols, k2);
                tmp.mltetrodeplacemap.plot();

                % 
            end
        end

        % Save the figure
        F = getframe(h);
        outputFolder = fullfile(session.analysisFolder, obj.config.canon_square_placemaps_folder);
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