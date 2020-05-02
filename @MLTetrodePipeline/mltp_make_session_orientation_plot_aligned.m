function mltp_make_session_orientation_plot_aligned(obj, session)
    if obj.verbose
        fprintf('Making the session orientation plot (aligned/canonical).\n');
    end

    h = figure('name', sprintf('Session %s', session.name), 'Position', get(0,'Screensize'));
    % Fixme! Increase the size if it wont fit the number of trials
    p = obj.config.session_orientation_plot.subplot_num_rows; 
    q = obj.config.session_orientation_plot.subplot_num_cols; 
    k = 1;
    sr = session.sessionRecord;
    ti = sr.getTrialsToProcess();
    for iTrial = 1:sr.getNumTrialsToProcess()
        trialId = ti(iTrial).id;
                
        trialCanonFilename = fullfile(session.analysisFolder, sprintf('trial_%d_movement.mat', trialId));
        fprintf('Loading %s ... ', trialCanonFilename);
        tmp = load(trialCanonFilename);
        fprintf('done!\n');
        movement = tmp.movement;

        subplot(p,q,k)
        plot(movement.x_cm, movement.y_cm, '.', 'color', obj.config.session_orientation_plot.trial_pos_colours(k));
        if obj.config.session_orientation_plot.subplot_show_title == 1
            title(sprintf('Trial %d', trialId))
        end
        hold on
        % Have the arena draw itself so this will work with any arena shape
        movement.arena.plotCanon();
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