        function mltp_nvt_split_into_trial_nvt(obj, session)
            if obj.verbose
                fprintf('Splitting NVT file data into separate trial_#_nvt.mat files.\n');
            end
            % Load the nvt file and split it into trials
            trials = ml_nlx_nvt_split_into_trials( fullfile(session.rawFolder, obj.config.nvt_filename), obj.config.nvt_file_trial_separation_threshold_s );
            % Save each trial's data as a separate mat filename
            numTrials = length(trials);
            session.num_trials_recorded = numTrials;
            for iTrial = 1:numTrials
                trial = trials{iTrial};
                trialNvtFilename = fullfile(session.analysisFolder, sprintf('trial_%d_nvt.mat', iTrial));
                if obj.verbose
                    fprintf('Saving %s... ', trialNvtFilename);
                end
                save(trialNvtFilename, 'trial');
                if obj.verbose
                    fprintf('done!\n');
                end
            end
        end % function