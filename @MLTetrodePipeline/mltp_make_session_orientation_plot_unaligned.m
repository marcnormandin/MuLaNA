function mltp_make_session_orientation_plot_unaligned(obj, session)
        if obj.verbose
            fprintf('Making the session orientation plot (using unaligned coordinates).\n');
        end

        h = figure('name', sprintf('Session %s', session.name), 'Position', get(0,'Screensize'));
        p = obj.config.session_orientation_plot.subplot_num_rows; 
        q = obj.config.session_orientation_plot.subplot_num_cols; 
        k = 1;
        sr = session.sessionRecord;
        ti = sr.getTrialsToProcess();
        for iTrial = 1:sr.getNumTrialsToProcess()
            trialId = ti(iTrial).id;
                
            trialFnvtFilename = fullfile(session.analysisFolder, sprintf('trial_%d_fnvt.mat', trialId));
            fprintf('Loading %s ... ', trialFnvtFilename);
            data = load(trialFnvtFilename);
            fprintf('done!\n');
            trial = data.trial;

            trialArenaroiFilename = fullfile(session.rawFolder, sprintf('trial_%d_arenaroi.mat', trialId));
            fprintf('Loading %s ... ', trialArenaroiFilename);
            data = load(trialArenaroiFilename);
            fprintf('done!\n');
            arenaroi = data.arenaroi;


            subplot(p,q,k)
            plot(trial.extractedX, trial.extractedY, '.', 'color', obj.config.session_orientation_plot.trial_pos_colours(k));
            if obj.config.session_orientation_plot.subplot_show_title == 1
                title(sprintf('Trial %d', trialId))
            end
            hold on
            % FixMe! This will probably mess up if not a square or
            % rectangle
            for iVertex = 1:length(arenaroi.xVertices)
                plot(arenaroi.xVertices(iVertex), arenaroi.yVertices(iVertex), 'o', 'markerfacecolor', obj.config.session_orientation_plot.arenaroi_vertex_markerfacecolours(iVertex), ...
                    'markeredgecolor', obj.config.session_orientation_plot.arenaroi_vertex_markeredgecolours(iVertex))
            end
            % draw a line representing the feature
            if obj.config.session_orientation_plot.draw_feature == 1
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
        outputFolder = session.analysisFolder;
        if ~isfolder(outputFolder) % should already exist
            mkdir(outputFolder)
        end
        imwrite(F.cdata, fullfile(outputFolder, sprintf('%s.png',fnPrefix)), 'png')
        savefig(h, fullfile(outputFolder, sprintf('%s.fig',fnPrefix)));
        close(h);    
    end % function