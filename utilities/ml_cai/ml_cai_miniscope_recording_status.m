
function [status] = ml_cai_miniscope_recording_status( trialFolder )
    fnSettings = fullfile(trialFolder, 'settings_and_notes.dat');
    fnTimestamp = fullfile(trialFolder, 'timestamp.dat');

    status = [];

    status.settingsAndNotes.exists = isfile(fnSettings);
    status.timestamp.exists = isfile(fnTimestamp);
    
    if ~status.settingsAndNotes.exists
        fprintf('The setttings and notes file (%s) does not exist.\n', fnSettings);
    end
    
    if ~status.timestamp.exists
        fprintf('The timestamp file (%s) does not exist.\n', fnTimestamp);
    end
    

    try 
        status.settingsAndNotes.san = DAQSettingsAndNotes(fnSettings);
        status.settingsAndNotes.isValid = 1;
    catch e
        %disp(e)
        %fprintf('settings and notes error\n');
        status.settingsAndNotes.isValid = 0;
    end

    if ~status.settingsAndNotes.isValid
        fprintf('The settings and notes file (%s) is invalid.\n', fnSettings);
    end
    
    try
        status.timestamp.ts = DAQTimeStamp( fnTimestamp );
        status.timestamp.isValid = 1;
    catch e
        %disp(e)
        %fprintf('timestamp error.\n');
        status.timestamp.isValid = 0;
    end
    
    if ~status.timestamp.isValid
        fprintf('The timestamp file (%s) is invalid.\n', fnTimestamp);
    end
    
    % Count the number of behavCam files
    status.behavCam.files = dir(fullfile(trialFolder, 'behavCam*.avi'));
    status.behavCam.numFiles = length( status.behavCam.files );
    % Count the number of frames to make sure that it matches the number of
    % frames recorded in the timestamp file
    status.behavCam.numFrames = 0;
    for iVideo = 1:status.behavCam.numFiles
        f = status.behavCam.files(iVideo);
        o = VideoReader( fullfile(f.folder, f.name) );
        status.behavCam.numFrames = status.behavCam.numFrames + round(o.Duration * o.FrameRate);
    end

    % Count the number of msCam files
    status.scopeCam.files = dir(fullfile(trialFolder, 'msCam*.avi'));
    status.scopeCam.numFiles = length( status.scopeCam.files );
    % Count the number of frames to make sure that it matches the number of
    % frames recorded in the timestamp file
    status.scopeCam.numFrames = 0;
    for iVideo = 1:status.scopeCam.numFiles
        f = status.scopeCam.files(iVideo);
        o = VideoReader( fullfile(f.folder, f.name) );
        status.scopeCam.numFrames = status.scopeCam.numFrames + round(o.Duration * o.FrameRate);
    end
    
    numCameras = 0;
    if status.behavCam.numFrames > 0
        numCameras = numCameras + 1;
    end
    if status.scopeCam.numFrames > 0
        numCameras = numCameras + 1;
    end
    
    if status.behavCam.numFrames == status.scopeCam.numFrames
        fprintf('The behaviour and scope cameras both have (%d) frames, which will make automatic determination impossible.\n', status.behavCam.numFrames);
        status.camerasAreDistinguishable = 0;
    else
        status.camerasAreDistinguishable = 1;
    end
    
    if status.timestamp.isValid
        if status.timestamp.ts.NumCameras() ~= numCameras
            fprintf('The timestamp file recorded (%d) cameras, but the there are only videos for (%d) cameras!\n', ...
                status.timestamp.ts.NumCameras(), numCameras);
        end

        tsFrames = zeros(1, status.timestamp.ts.NumCameras());
        cameraIds = status.timestamp.ts.CameraIds();
        for iCamera = 1:status.timestamp.ts.NumCameras()
           cam = status.timestamp.ts.CameraSubset(cameraIds(iCamera));
           tsFrames(iCamera) = length(cam.frameNum);
        end

        vidFrames = [status.behavCam.numFrames, status.scopeCam.numFrames];
        if ~isempty(setdiff(tsFrames, vidFrames))
            fprintf('The number of camera frames does not match the number of timestamps recorded for at least one of the cameras!\n');
        end
    end
    
    % Now we should actually check the timestamp file to make sure that the
    % number of video files is also valid.
    % Fixme!
    status.isValid = status.settingsAndNotes.isValid & status.timestamp.isValid;
    
    if status.settingsAndNotes.isValid
        status.sanString = status.settingsAndNotes.san.animal;
    else
        status.sanString = '** ERROR **';
    end

end % function


