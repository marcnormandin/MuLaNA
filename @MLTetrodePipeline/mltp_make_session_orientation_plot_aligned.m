function mltp_make_session_orientation_plot_aligned(obj, session)
    if obj.verbose
        fprintf('Making the session orientation plot (aligned/canonical).\n');
    end

    h = figure('name', sprintf('Session %s', session.name), 'Position', get(0,'Screensize'));
    p = obj.config.session_orientation_plot.subplot_num_rows; 
    q = obj.config.session_orientation_plot.subplot_num_cols; 
    k = 1;
    for iTrial = 1:session.num_trials_recorded
        trialCanonFilename = fullfile(session.analysisFolder, sprintf('trial_%d_canon_rect.mat', iTrial));
        fprintf('Loading %s ... ', trialCanonFilename);
        data = load(trialCanonFilename);
        fprintf('done!\n');
        canon = data.canon;

        arenaroi = canon.arenaroi;


        subplot(p,q,k)
        plot(canon.pos.x, canon.pos.y, '.', 'color', obj.config.session_orientation_plot.trial_pos_colours(k));
        if obj.config.session_orientation_plot.subplot_show_title == 1
            title(sprintf('Trial %d', iTrial))
        end
        hold on
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
    fnPrefix = 'session_orientation_plot_aligned';
    outputFolder = session.analysisFolder;
    if ~isfolder(outputFolder) % should already exist
        mkdir(outputFolder)
    end
    imwrite(F.cdata, fullfile(outputFolder, sprintf('%s.png',fnPrefix)), 'png')
    savefig(h, fullfile(outputFolder, sprintf('%s.fig',fnPrefix)));
    close(h);
end % function