function mltp_make_session_orientation_plot_aligned(obj, session)
    if obj.isVerbose()
        fprintf('Making the session orientation plot (aligned/canonical).\n');
    end

    h = figure('name', sprintf('Session %s', session.getName()), 'Position', get(0,'Screensize'));
    % Fixme! Increase the size if it wont fit the number of trials
    p = obj.Config.session_orientation_plot.subplot_num_rows; 
    q = obj.Config.session_orientation_plot.subplot_num_cols; 
    k = 1;
    
    for iTrial = 1:session.getNumTrials()
        trial = session.getTrialByOrder(iTrial);
        trialId = trial.getTrialId();
        sliceId = trial.getSliceId();
                
        trialCanonFilename = fullfile(session.getAnalysisDirectory(), sprintf('slice_%d_movement.mat', sliceId));
        fprintf('Loading %s ... ', trialCanonFilename);
        tmp = load(trialCanonFilename);
        fprintf('done!\n');
        movement = tmp.movement;

        if movement.sliceId ~= sliceId
            error('Data integrity error. The slice id (%d) in the movement file (%s) does not match the slice id (%d) of the trial (%d) being processed.\n', ...
                movement.sliceId, trialCanonFilename, sliceId, trialId);
        end
        
        subplot(p,q,trialId)
        plot(movement.x_cm, movement.y_cm, '.', 'color', obj.Config.session_orientation_plot.trial_pos_colours(trial.getContextId()));
        if obj.Config.session_orientation_plot.subplot_show_title == 1
            title(sprintf('T: %d, S: %d, C: %d', trialId, sliceId, trial.getContextId()))
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
    outputFolder = session.getAnalysisDirectory();
    if ~isfolder(outputFolder) % should already exist
        mkdir(outputFolder)
    end
    imwrite(F.cdata, fullfile(outputFolder, sprintf('%s.png',fnPrefix)), 'png')
    savefig(h, fullfile(outputFolder, sprintf('%s.fig',fnPrefix)));
    close(h);
end % function
