function mltp_nvt_split_into_trial_nvt(obj, session)
    if obj.isVerbose()
        fprintf('Splitting NVT file data into separate trial_#_nvt.mat files.\n');
    end
    % Load the nvt file and split it into trials
    trialsData = ml_nlx_nvt_split_into_trials( fullfile(session.getSessionDirectory(), obj.Experiment.getNvtFilename()), obj.Experiment.getNvtTrialSeparationThresholdS() );
    % Save each trial's data as a separate mat filename
    numTrials = length(trialsData);

    % Make sure that the session record and what we split is
    % consistent
    if numTrials ~= session.getNumTrials() % all the trials, including ones we dont want to process
        error('Session records are inconsistent. The session record has (%d) trials, but we just split (%d).', ...
            session.getNumTrials(), numTrials);
    end

    % Save a separate file for each trial in the nvt file, but only for
    % ones that we will process
    for iTrial = 1:session.getNumTrials()
        trial = session.getTrial(iTrial);
        
        trialNvtFilename = fullfile(session.getAnalysisDirectory(), sprintf('trial_%d_nvt.mat', trial.getTrialId()));
        if obj.isVerbose()
            fprintf('Saving %s... ', trialNvtFilename);
        end
        
        % get the trials data
        trial = trialsData{iTrial};
        
        save(trialNvtFilename, 'trial');
        if obj.isVerbose()
            fprintf('done!\n');
        end
    end
end % function
