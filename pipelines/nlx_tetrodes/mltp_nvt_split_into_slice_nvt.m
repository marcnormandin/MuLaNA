function mltp_nvt_split_into_slice_nvt(obj, session)
    if obj.isVerbose()
        fprintf('Splitting NVT file data into separate slice_#_nvt.mat files.\n');
    end
    % Load the nvt file and split it into slices
    slicesData = ml_nlx_nvt_split_into_slices( fullfile(session.getSessionDirectory(), obj.Experiment.getNvtFilename()), obj.Experiment.getNvtTrialSeparationThresholdS() );
    
    numSlices = length(slicesData);
    
    % Make sure that the session data (found from the session_record.json
    % files) matches the number of slices we made from slicing the nvt
    % data. This could happen if the session records were modified or the
    % threshold used is not the same as used when generating the session
    % records.
    if numSlices ~= session.getSessionRecord().getNumSlices()
        error('The nvt file was split into %d slices, but the session has %d slices. The data is inconsistent. Check the session_record.json file.', numSlices, session.getNumSlices());
    end

    % Save a separate file for each slice in the nvt file, but only those that are trials.
    for iSlice = 1:numSlices
        
        sliceNvtFilename = fullfile(session.getAnalysisDirectory(), sprintf('slice_%d_nvt.mat', iSlice));
        if obj.isVerbose()
            fprintf('Saving %s... ', sliceNvtFilename);
        end
        
        % get the trials data
        slice = slicesData{iSlice};
        
        if slice.slice_id ~= iSlice
            error('Slice id mismatch! (%d vs %d)',slice.slice_id, iSlice);
        end
        
        slice.created = ml_util_gen_datetag();
        
        save(sliceNvtFilename, 'slice');
        if obj.isVerbose()
            fprintf('done!\n');
        end
    end
end % function
