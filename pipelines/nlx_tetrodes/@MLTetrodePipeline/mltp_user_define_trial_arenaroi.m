function mltp_user_define_trial_arenaroi(obj, session, trial)
    if obj.isVerbose()
        fprintf('Defining the ROI for one trial.\n');
    end

    trialId = trial.getTrialId();

    % Changed from fnvt to nvt to allow for the fnvt creation to use
    % the ROI bounds to exclude outliers.
    trialFnvtFilename = fullfile(session.getAnalysisDirectory(), sprintf('trial_%d_nvt.mat', trialId));
    fprintf('Loading %s ... ', trialFnvtFilename);
    data = load(trialFnvtFilename);
    fprintf('done!\n');
    tdata = data.trial;

    [xVertices, yVertices] = ml_nlx_user_select_arena_roi( tdata.extractedX, tdata.extractedY, sprintf('TrialId %d', trialId) );
    arenaroi.xVertices = xVertices;
    arenaroi.yVertices = yVertices;

    % Save it in the recording folder, as we will treat
    % it like raw data (and it takes a lot of user time
    % to create).
    roiFilename = fullfile(session.getSessionDirectory(), sprintf('trial_%d_arenaroi.mat', trialId));
    if obj.isVerbose()
        fprintf('Saving ROI to %s ... ', roiFilename);
    end
    save(roiFilename, 'arenaroi')
    if obj.isVerbose()
        fprintf('done!\n');
    end
end % function
