function ml_motion_save_h5( motionData, outputFilename )
    %% This function saves the motion data in HDF5 file format.
    
    % Create the file
    if isfile(outputFilename)
        delete(outputFilename)
    end
    fid = H5F.create(outputFilename);
    H5F.close(fid);

    numSamples = motionData.track.numSamples;
    
    % Record useful attributes
    h5writeatt(outputFilename, '/', 'recording_enclosed', motionData.track.enclosed); % We save an entire session's raw motion tracking
    h5writeatt(outputFilename, '/', 'recording_year', motionData.recording.year);
    h5writeatt(outputFilename, '/', 'recording_month', motionData.recording.month);
    h5writeatt(outputFilename, '/', 'recording_day', motionData.recording.day);
    h5writeatt(outputFilename, '/', 'recording_hour', motionData.recording.hour);
    h5writeatt(outputFilename, '/', 'recording_minute', motionData.recording.minute);
    h5writeatt(outputFilename, '/', 'recording_second', motionData.recording.second);
    h5writeatt(outputFilename, '/', 'recording_date_str', motionData.recording.dateString);
    h5writeatt(outputFilename, '/', 'recording_time_str', motionData.recording.timeString);

    h5writeatt(outputFilename, '/', 'num_samples', numSamples);
    h5writeatt(outputFilename, '/', 'recording_system', motionData.track.recordingSystem);
    h5writeatt(outputFilename, '/', 'recording_coordinate_system', motionData.track.coordinateSystem);
    h5writeatt(outputFilename, '/', 'position_unit', motionData.track.positionUnits);
    h5writeatt(outputFilename, '/', 'angle_unit', motionData.track.angleUnits);
    h5writeatt(outputFilename, '/', 'time_unit', motionData.track.timeUnits);
    h5writeatt(outputFilename, '/', 'filter_type', motionData.track.filterType);

    % Record the data arrays
    h5create(outputFilename, '/sample_num', [numSamples]);
    h5write(outputFilename, '/sample_num', motionData.track.sampleNum);

    h5create(outputFilename, '/x', [numSamples]);
    h5write(outputFilename, '/x', motionData.track.x);

    h5create(outputFilename, '/y', [numSamples]);
    h5write(outputFilename, '/y', motionData.track.y);

    h5create(outputFilename, '/t', [numSamples]);
    h5write(outputFilename, '/t', motionData.track.t);

    h5create(outputFilename, '/angle', [numSamples]);
    h5write(outputFilename, '/angle', motionData.track.angle);
end % function
    