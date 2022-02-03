function [motionData] = ml_motion_load_h5( filename )
    % This code read in the motion data from an HDF5 file.
    
    if ~isfile(filename)
        error('Unable to load the motion data. The file (%s) does not exist.', filename);
    end
    
    header = ml_cai_core_h5_read_header( filename );
    recording.hour = header.recording_hour;
    recording.minute = header.recording_minute;
    recording.second = header.recording_second;
    recording.year = header.recording_year;
    recording.month = header.recording_month;
    recording.day = header.recording_day;
    recording.dateString = header.recording_date_str;
    recording.timeString = header.recording_time_str;

    track.numSamples = header.num_samples;
    track.angleUnits = header.angle_unit;
    track.positionUnits = header.position_unit;
    track.timeUnits = header.time_unit;
    track.enclosed = header.recording_enclosed;
    track.filterType = header.filter_type;
    track.recordingSystem = header.recording_system;
    track.coordinateSystem = header.recording_coordinate_system;

    track.x = h5read( filename, '/x' );
    track.y = h5read( filename, '/y' );
    track.angle = h5read( filename, '/angle' );
    track.t = h5read( filename, '/t' );
    track.sampleNum = h5read( filename, '/sample_num' );

    motionData.recording = recording;
    motionData.track = track;
end % function


