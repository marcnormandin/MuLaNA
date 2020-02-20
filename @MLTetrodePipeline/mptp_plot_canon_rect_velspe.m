function mptp_plot_canon_rect_velspe(obj, session)
    outputFolder = fullfile( session.analysisFolder, 'trial_movement' );
    if ~exist( outputFolder, 'dir')
        mkdir(outputFolder)
    end
    
    for iTrial = 1:session.num_trials_recorded
        fn = fullfile( session.analysisFolder, sprintf('trial_%d_canon_rect.mat', iTrial) );
        if ~isfile(fn)
            error('The required file (%s) does not exist:', fn);
        end
        tmp = load(fn);
        canon = tmp.canon;
        
        dx = diff(canon.pos.x);
        dy = diff(canon.pos.y);
        dt = diff(canon.timeStamps_mus./10^6);
        t = canon.timeStamps_mus./10^6;
        t = t - t(1);
        vx = dx./dt;
        vx = [0 vx];

        vy = dy./dt;
        vy = [0, vy];

        h = figure;
        p = 3; q = 1; k = 1;

        ax(k) = subplot(p,q,k);
        k = k + 1;
        plot(t, vx,'b.');
        hold on
        plot(t, canon.vel.x, 'r-', 'linewidth', 2)
%         yline(obj.config.placemaps.criteria_speed_cm_per_second_minimum,'k', 'linewidth', 2)
%         if isfinite(obj.config.placemaps.criteria_speed_cm_per_second_maximum)
%             yline(obj.config.placemaps.criteria_speed_cm_per_second_maximum,'k', 'linewidth', 2)
%             yline(-obj.config.placemaps.criteria_speed_cm_per_second_maximum,'k', 'linewidth', 2)
%         end
%         yline(-obj.config.placemaps.criteria_speed_cm_per_second_minimum,'k', 'linewidth', 2)
        grid on
        ylabel('v_x(t) [cm/s]')
        title(sprintf('%s %s Trial %d', obj.experiment.subjectName, session.name, iTrial), 'interpreter', 'none');

        ax(k) = subplot(p,q,k);
        k = k + 1;
        plot(t, vy,'b.');
        hold on
        plot(t, canon.vel.y,'r-', 'linewidth', 2)
%         yline(obj.config.placemaps.criteria_speed_cm_per_second_minimum,'k', 'linewidth', 2)
%         yline(obj.config.placemaps.criteria_speed_cm_per_second_maximum,'k', 'linewidth', 2)
%         yline(-obj.config.placemaps.criteria_speed_cm_per_second_minimum,'k', 'linewidth', 2)
%         yline(-obj.config.placemaps.criteria_speed_cm_per_second_maximum,'k', 'linewidth', 2)
        grid on
        ylabel('v_y(t) [cm/s]')

        ax(k) = subplot(p,q,k);
        k = k + 1;
        hold on
        plot(t, canon.spe,'r-', 'linewidth', 2)
        yline(obj.config.placemaps.criteria_speed_cm_per_second_minimum,'k', 'linewidth', 2)
        if isfinite(obj.config.placemaps.criteria_speed_cm_per_second_maximum)
            yline(obj.config.placemaps.criteria_speed_cm_per_second_maximum,'k', 'linewidth', 2)
            yline(-obj.config.placemaps.criteria_speed_cm_per_second_maximum,'k', 'linewidth', 2)
        end
        grid on
        ylabel('s(t) [cm/s]')


        xlabel('Trial time, t [s]')
        linkaxes(ax, 'x')
        axis tight
        
        trialPlotFilenamePrefix = fullfile(outputFolder, sprintf('trial_%d_canrectvelspe', iTrial));
        savefig(h, sprintf('%s.fig', trialPlotFilenamePrefix))
        saveas(h, sprintf('%s.png', trialPlotFilenamePrefix), 'png');
                
        close(h);
    end % iTrial
end % function
