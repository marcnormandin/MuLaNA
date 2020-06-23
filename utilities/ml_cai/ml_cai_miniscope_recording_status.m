
function [status] = ml_cai_miniscope_recording_status( trialFolder )
    fnSettings = fullfile(trialFolder, 'settings_and_notes.dat');
    fnTimestamp = fullfile(trialFolder, 'timestamp.dat');

    status = [];

    status.settingsAndNotes.exists = isfile(fnSettings);
    status.timestamp.exists = isfile(fnTimestamp);

    try 
        status.settingsAndNotes.san = DAQSettingsAndNotes(fnSettings);
        status.settingsAndNotes.isValid = 1;
    catch e
        %disp(e)
        %fprintf('settings and notes error\n');
        status.settingsAndNotes.isValid = 0;
    end

    try
        status.timestamp.ts = DAQTimeStamp( fnTimestamp );
        status.timestamp.isValid = 1;
    catch e
        %disp(e)
        %fprintf('timestamp error.\n');
        status.timestamp.isValid = 0;
    end
    
    % Count the number of behavCam files
    status.behavCam.files = dir(fullfile(trialFolder, 'behavCam*.avi'));
    status.behavCam.numFiles = length( status.behavCam.files );

    % Count the number of msCam files
    status.scopeCam.files = dir(fullfile(trialFolder, 'msCam*.avi'));
    status.scopeCam.numFiles = length( status.scopeCam.files );

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

