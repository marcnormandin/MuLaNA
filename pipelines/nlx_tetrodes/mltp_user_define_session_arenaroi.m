function mltp_user_define_session_arenaroi(obj, session)
    % We need to define the ROI for each slice of data, not just the trials
    % because the user may find problems with the slices and not use them
    % as trials.
    
    if obj.isVerbose()
        fprintf('Defining the ROI for all trials of the session.\n');
    end

    % Get the sliced nvt files
    regStr = '^(slice_)\d+(_nvt.mat)$';
    nvtFilenames = ml_dir_regexp_files(session.getAnalysisDirectory(), regStr, false);
    numSlices = length(nvtFilenames);
    
    for iSlice = 1:numSlices
        % Changed from fnvt to nvt to allow for the fnvt creation to use
        % the ROI bounds to exclude outliers.
        sliceNvtFilename = nvtFilenames{iSlice};
        
        fprintf('Loading %s ... ', sliceNvtFilename);
        data = load(sliceNvtFilename);
        fprintf('done!\n');
        sdata = data.slice;

        [xVertices, yVertices] = ml_nlx_user_select_arena_roi( sdata.extractedX, sdata.extractedY, sprintf('Slice Id %d', sdata.slice_id) );
        arenaroi.xVertices = xVertices;
        arenaroi.yVertices = yVertices;

        % Save it in the recording folder, as we will treat
        % it like raw data (and it takes a lot of user time
        % to create so we don't want to do this over and over again).
        roiFilename = fullfile(session.getSessionDirectory(), sprintf('slice_%d_arenaroi.mat', sdata.slice_id));
        if obj.isVerbose()
            fprintf('Saving ROI to %s ... ', roiFilename);
        end
        save(roiFilename, 'arenaroi')
        if obj.isVerbose()
            fprintf('done!\n');
        end
    end
end % function
