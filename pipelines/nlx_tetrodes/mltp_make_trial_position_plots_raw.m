function mltp_make_trial_position_plots_raw(obj, session)
            if obj.isVerbose()
                fprintf('Making position plots\n');
            end

            % Make the folder if it does not exist
            folder = fullfile(session.getAnalysisDirectory(), obj.Config.trial_nvt_position_plots_folder);
            if ~exist(folder, 'dir')
                mkdir(folder)
            end

            for iTrial = 1:session.getNumTrials()
                trial = session.getTrialByOrder(iTrial);
                trialId = trial.getTrialId();
                sliceId = trial.getSliceId();
                
                trialNvtFilename = fullfile(session.getAnalysisDirectory(), sprintf('slice_%d_nvt.mat', sliceId));
                fprintf('Loading %s ... ', trialNvtFilename);
                data = load(trialNvtFilename);
                fprintf('done!\n');
                t = data.slice;

                % 1)  Scatter plot 
                h = figure('Position', get(0,'Screensize'));
                plot(t.extractedX, t.extractedY, 'b.')
                set(gca, 'ydir', 'reverse')
                axis equal off
                title(sprintf('Trial: %d, Slice: %d, Context: %d\n Dig: %s', trialId, sliceId, trial.getContextId(), trial.getDig()))

                % Save the data here
                trialPlotFilenamePrefix = fullfile(folder, sprintf('trial_%d_pos_scatter', trialId));
                fprintf('Saving plots %s ... ', trialPlotFilenamePrefix);
                savefig(h, sprintf('%s.fig', trialPlotFilenamePrefix))
                saveas(h, sprintf('%s.png', trialPlotFilenamePrefix), 'png');
                fprintf('done!\n');

                close(h);



                % Start the time axis origin at the start of the trial
                ts = t.timeStamps_mus;
                ts = ts - ts(1);
                ts = ts / 10^6; % convert from microseconds to seconds


                % Timeseries plot
                h = figure('Position', get(0,'Screensize'));

                ax(1) =  subplot(3,1,1);
                plot(ts, t.extractedX, 'r.-');
                xlabel('Trial time, t (s)')
                ylabel('X Position (px)')
                grid on
                title(sprintf('Trial: %d, Slice: %d, Context: %d\n Dig: %s', trialId, sliceId, trial.getContextId(), trial.getDig()))


                ax(2) = subplot(3,1,2);
                plot(ts, t.extractedY, 'b.-')
                xlabel('Trial time, t (s)')
                ylabel('Y Position (px)')
                grid on

                ax(3) = subplot(3,1,3);
                plot(ts, t.extractedAngle, 'k.-')
                xlabel('Trial time, t (s)')
                ylabel('Angle (deg)')
                grid on

                linkaxes(ax, 'x');

                % Save the data here
                trialPlotFilenamePrefix = fullfile(folder, sprintf('trial_%d_pos_timeseries', trialId));
                fprintf('Saving plots %s ... ', trialPlotFilenamePrefix);
                savefig(h, sprintf('%s.fig', trialPlotFilenamePrefix))
                saveas(h, sprintf('%s.png', trialPlotFilenamePrefix), 'png');
                fprintf('done!\n');

                close(h);
            end    
        end % function
