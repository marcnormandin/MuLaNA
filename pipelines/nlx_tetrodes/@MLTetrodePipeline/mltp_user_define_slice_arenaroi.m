function mltp_user_define_slice_arenaroi(obj, session, trial)
    if obj.isVerbose()
        fprintf('Defining the ROI for one trial (a used slice).\n');
    end

    trialId = trial.getTrialId();
    sliceId = trial.getSliceId();

    % Changed from fnvt to nvt to allow for the fnvt creation to use
    % the ROI bounds to exclude outliers.
    trialNvtFilename = fullfile(session.getAnalysisDirectory(), sprintf('slice_%d_nvt.mat', sliceId));
    fprintf('Loading %s ... ', trialNvtFilename);
    data = load(trialNvtFilename);
    fprintf('done!\n');
    sData = data.slice;

    [xVertices, yVertices] = ml_nlx_user_select_arena_roi( sData.extractedX, sData.extractedY, sprintf('Trial ID: %d\nSlice ID: %d', trialId, sliceId) );
    arenaroi.xVertices = xVertices;
    arenaroi.yVertices = yVertices;
    arenaroi.sliceId = sliceId;
    arenaroi.trialId = trialId;

    % Save it in the recording folder, as we will treat
    % it like raw data (and it takes a lot of user time
    % to create).
    roiFilename = fullfile(session.getSessionDirectory(), sprintf('slice_%d_arenaroi.mat', sliceId));
    if obj.isVerbose()
        fprintf('Saving ROI to %s ... ', roiFilename);
    end
    save(roiFilename, 'arenaroi')
    if obj.isVerbose()
        fprintf('done!\n');
    end
end % function
