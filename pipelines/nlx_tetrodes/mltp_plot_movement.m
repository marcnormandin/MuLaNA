function mltp_plot_movement(obj, session)
    outputFolder = fullfile( session.getAnalysisDirectory(), 'trial_movement' );
    if ~exist( outputFolder, 'dir')
        mkdir(outputFolder)
    end
    
%     for iTrial = 1:session.getNumTrials()
%         trial = session.getTrial(iTrial);
    for iTrial = 1:session.getNumTrials()
        trial = session.getTrialByOrder(iTrial);
        trialId = trial.getTrialId();
        sliceId = trial.getSliceId();
                
        fn = fullfile( session.getAnalysisDirectory(), sprintf('slice_%d_movement.mat', sliceId) );
        if ~isfile(fn)
            error('The required file (%s) does not exist:', fn);
        end
        tmp = load(fn);
        movement = tmp.movement;
        t = movement.timestamps_ms ./ 10^3;
        t = t - t(1);
        
        h = figure('position', get(0, 'ScreenSize'));
        p = 3; q = 2;

        ax(1) = subplot(p,q,1);
        plot(t, movement.vx,'b.');
        hold on
        plot(t, movement.vx_smoothed, 'r-', 'linewidth', 2)
        grid on
        ylabel('v_x(t) [cm/s]')
        title(sprintf('%s %s\n T: %d, S: %d, C: %d', obj.Experiment.getAnimalName(), session.getName(), trialId, sliceId, trial.getContextId()), 'interpreter', 'none');

        ax(2) = subplot(p,q,3);
        plot(t, movement.vy,'b.');
        hold on
        plot(t, movement.vy_smoothed,'r-', 'linewidth', 2)
        grid on
        ylabel('v_y(t) [cm/s]')

        ax(3) = subplot(p,q,5);
        plot(t, movement.speed_cm_per_s, 'b.');
        hold on
        plot(t, movement.speed_smoothed_cm_per_s,'r-', 'linewidth', 2)
        yline(obj.Config.placemaps.criteria_speed_cm_per_second_minimum,'k', 'linewidth', 2)
        if isfinite(obj.Config.placemaps.criteria_speed_cm_per_second_maximum)
            yline(obj.Config.placemaps.criteria_speed_cm_per_second_maximum,'k', 'linewidth', 2)
            yline(-obj.Config.placemaps.criteria_speed_cm_per_second_maximum,'k', 'linewidth', 2)
        end
        grid on
        ylabel('s(t) [cm/s]')
        xlabel('Trial time, t [s]')
        linkaxes(ax, 'x')
        axis tight
        
        % Plot the 2d plot on the right side
        subplot(p,q, [2, 4, 6]);
        scatter(movement.x_cm, movement.y_cm, 4, movement.speed_smoothed_cm_per_s, 'filled')
        set(gca, 'ydir', 'reverse')
        set(gca, 'color', 'k')
        axis equal tight
        title('Canonical Space (cm)')
        grid on
        colormap jet
        hcb = colorbar;
        colorTitleHandle = get(hcb,'Title');
        titleString = 'Speed (cm/s)';
        set(colorTitleHandle ,'String',titleString);

        
        trialPlotFilenamePrefix = fullfile(outputFolder, sprintf('trial_%d_movement', trialId));
        savefig(h, sprintf('%s.fig', trialPlotFilenamePrefix))
        saveas(h, sprintf('%s.png', trialPlotFilenamePrefix), 'png');
                
        close(h);
    end % trialId
end % function
