function mltp_make_session_orientation_plot_unaligned(obj, session)
        if obj.isVerbose()
            fprintf('Making the session orientation plot (using unaligned coordinates).\n');
        end

        h = figure('name', sprintf('Session %s', session.getName()), 'Position', get(0,'Screensize'));
        p = obj.Config.session_orientation_plot.subplot_num_rows; 
        q = obj.Config.session_orientation_plot.subplot_num_cols; 
        k = 1;
        for iTrial = 1:session.getNumTrials()
            trial = session.getTrialByOrder(iTrial);
            trialId = trial.getTrialId();
            sliceId = trial.getSliceId();
                
            trialFnvtFilename = fullfile(session.getAnalysisDirectory(), sprintf('slice_%d_fnvt.mat', sliceId));
            fprintf('Loading %s ... ', trialFnvtFilename);
            data = load(trialFnvtFilename);
            fprintf('done!\n');
            tdata = data.slice;

            trialArenaroiFilename = fullfile(session.getSessionDirectory(), sprintf('slice_%d_arenaroi.mat', sliceId));
            fprintf('Loading %s ... ', trialArenaroiFilename);
            data = load(trialArenaroiFilename);
            fprintf('done!\n');
            arenaroi = data.arenaroi;


            subplot(p,q,trialId)
            plot(tdata.extractedX, tdata.extractedY, '.', 'color', obj.Config.session_orientation_plot.trial_pos_colours(trial.getContextId()));
            if obj.Config.session_orientation_plot.subplot_show_title == 1
                title(sprintf('T: %d, S: %d, C: %d', trialId, sliceId, trial.getContextId()))
            end
            hold on
            % FixMe! This will probably mess up if not a square or
            % rectangle
            for iVertex = 1:length(arenaroi.xVertices)
                plot(arenaroi.xVertices(iVertex), arenaroi.yVertices(iVertex), 'o', 'markerfacecolor', obj.Config.session_orientation_plot.arenaroi_vertex_markerfacecolours(iVertex), ...
                    'markeredgecolor', obj.Config.session_orientation_plot.arenaroi_vertex_markeredgecolours(iVertex))
            end
            % draw a line representing the feature
            if obj.Config.session_orientation_plot.draw_feature == 1
                plot(arenaroi.xVertices(1:2), arenaroi.yVertices(1:2), 'k-', 'linewidth', 2)
            end
            set(gca, 'ydir', 'reverse');
            axis equal off
            hold on
            k = k + 1;

        end % trial

        % Save the figure
        F = getframe(h);
        fnPrefix = 'session_orientation_plot_unaligned';
        outputFolder = session.getAnalysisDirectory();
        if ~isfolder(outputFolder) % should already exist
            mkdir(outputFolder)
        end
        imwrite(F.cdata, fullfile(outputFolder, sprintf('%s.png',fnPrefix)), 'png')
        savefig(h, fullfile(outputFolder, sprintf('%s.fig',fnPrefix)));
        close(h);    
    end % function
