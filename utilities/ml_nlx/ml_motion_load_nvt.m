function [motionData] = ml_motion_load_nvt( nvtFilename )
    %% This function read in the motion tracking coordinates from the Neuralynx
    %% file format (custom).

    if ~isfile(nvtFilename)
        error('The file (%s) does not exist. Can not export motion tracking coordinates.\n', nvtFilename);
    end

    recording = ml_nlx_nvt_get_recording_datetime( nvtFilename );

    [TimeStamps, ExtractedX, ExtractedY, ExtractedAngle, Targets, Points, Header] = ml_nlx_nvt_load(  nvtFilename );
    numSamples = length(ExtractedX);

    track.x = ExtractedX;
    track.y = ExtractedY;
    track.t = TimeStamps;
    track.angle = ExtractedAngle;
    track.sampleNum = 1:numSamples;
    track.numSamples = numSamples;
    track.timeUnits = 'microseconds';
    track.positionUnits = 'pixels';
    track.angleUnits = 'degs';
    track.coordinateSystem = 'video';
    track.filterType = 'raw';
    track.recordingSystem = 'neuralynx_tetrodes';
    track.enclosed = 'session';
    
    motionData.recording = recording;
    motionData.track = track;
    motionData.input_nvtFilename = nvtFilename;
    
    
    rois = ml_cai_load_session_rois(recordingsSessionFolder, processTrialNames);
    
    motionData.rois = rois; % ADD, but seems like a bad design
end % function