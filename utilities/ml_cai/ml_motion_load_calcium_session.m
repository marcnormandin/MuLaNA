function [motionData] = ml_motion_load_calcium_session( recordingsSessionFolder )
    % Make the record. This should be done better, but no time.
    recordingOpened.hour = 1;
    recordingOpened.minute = 1;
    recordingOpened.second = 1;

    recordingOpened.year = 1979;
    recordingOpened.month = 4;
    recordingOpened.day = 28;
    
    recordingOpened.dateString = sprintf('%d-%d-%d', recordingOpened.year, recordingOpened.month, recordingOpened.day);
    recordingOpened.timeString = sprintf('%d:%d:%d', recordingOpened.hour, recordingOpened.minute, recordingOpened.second);
    
    
    sessionRecord = ml_util_json_read( fullfile(recordingsSessionFolder, 'session_record.json') );
    useTrial = sessionRecord.trial_info.use;
    trialNames = sessionRecord.trial_info.folders;
    badInds = find(useTrial ~= 1);
    processTrialNames = trialNames;
    processTrialNames(badInds) = [];

    dlcSessionFolder = strrep(recordingsSessionFolder, 'recordings_sep', 'dlc_tracks_sep');

    session_timestamps_ms = ml_cai_load_session_timestamps_ms(recordingsSessionFolder, processTrialNames);
    session_tracks = ml_cai_load_session_tracks(dlcSessionFolder, processTrialNames);
    rois = ml_cai_load_session_rois(recordingsSessionFolder, processTrialNames);

    if size(session_tracks,1) ~= length(session_timestamps_ms) || size(session_tracks,1) < 1
        error('FUCK! %s %s\n', mouseName, sessionName);
    end

    session_tracks.timestamps_ms = session_timestamps_ms;

    numSamples = length(session_timestamps_ms);
    
    % Now pick a part
    partName = 'led';

    partName_x = sprintf('track_%s_x', partName);
    partName_y = sprintf('track_%s_y', partName);
    partName_l = sprintf('track_%s_likelihood', partName);

    t_ms = session_tracks.timestamps_ms;
    x_px = session_tracks.(partName_x);
    y_px = session_tracks.(partName_y);
    l = session_tracks.(partName_l);

    track.x = x_px;
    track.y = y_px;
    track.t = t_ms;
    %track.likelihood = l;
    track.angle = nan(size(track.x)); % should calculate from the other tracks
    
    % DO NOT REMOVE, just flag them with nan
    badInds = find(l < 0.98);
    track.x(badInds) = nan;
    track.y(badInds) = nan;
    track.t(badInds) = nan;
    track.angle(badInds) = nan;
    
    track.sliceId = session_tracks.slice_id;
    
    track.sampleNum = 1:numSamples;
    track.numSamples = numSamples;
    track.timeUnits = 'milliseconds';
    track.positionUnits = 'pixels';
    track.angleUnits = 'degs';
    track.coordinateSystem = 'video';
    track.filterType = 'raw';
    track.recordingSystem = 'ucla_deeplabcut';
    track.enclosed = 'session';
    
    motionData.recording = recordingOpened;
    motionData.track = track;
    motionData.input_recordingsSessionFolder = recordingsSessionFolder;
    motionData.rois = rois;
end % function


function [rois] = ml_cai_load_session_rois(recordingsSessionFolder, trialFolders)    
    %rois = [];

    slice_id = 0;
    for i = 1:length(trialFolders)
       tn = trialFolders{i};

       rf = fullfile(recordingsSessionFolder, tn, 'behavcam_roi.mat');
       if ~isfile(rf)
           fprintf('Unable to find %s\n', rf);
           continue;
       end
       
       slice_id = slice_id + 1;
       
       data = load(rf);
       behavcam_roi = data.behavcam_roi;
       roi.x_px = behavcam_roi.inside.j;
       roi.y_px = behavcam_roi.inside.i;
       roi.shape = 'rectangle';
       roi.slice_id = slice_id;
       
       rois(slice_id) = roi;
    end
end % function
    
    
function [session_tracks] = ml_cai_load_session_tracks(dlcSessionFolder, trialFolders)
    %trialFolders = ml_cai_io_trialfolders_find(dlcSessionFolder);
    %trialFolders = {trialFolders.name};

    session_tracks = [];

    slice_id = 0;
    for i = 1:length(trialFolders)
       tn = trialFolders{i};

       s = split(tn, '_');

        % trial start time
        t0 = str2num(s{1}(2:end)) * 60 * 60;
        t0 = t0 + str2num(s{2}(2:end)) * 60;
        t0 = t0 + str2num(s{3}(2:end));
        t0 = t0 * 1000.0; % convert to milliseconds


       rf = fullfile(dlcSessionFolder, tn, 'tracks.posv');
       if ~isfile(rf)
           fprintf('Unable to find %s\n', rf);
           continue;
       end
       trial_tracks = readtable(rf, 'filetype', 'text');
       
       slice_id = slice_id + 1;
       slice_ids = slice_id * ones(size(trial_tracks,1),1);
       trial_tracks.slice_id = slice_ids;

       session_tracks = [session_tracks; trial_tracks];
    end
end % function

    

function [session_timestamps_ms] = ml_cai_load_session_timestamps_ms(recordingsSessionFolder, trialFolders)

    %trialFolders = ml_cai_io_trialfolders_find(recordingsSessionFolder);
    %trialFolders = {trialFolders.name};

    session_timestamps_ms = [];

    for i = 1:length(trialFolders)
       tn = trialFolders{i};

       s = split(tn, '_');

        % trial start time
        t0 = str2num(s{1}(2:end)) * 60 * 60;
        t0 = t0 + str2num(s{2}(2:end)) * 60;
        t0 = t0 + str2num(s{3}(2:end));
        t0 = t0 * 1000.0; % convert to milliseconds


       rf = fullfile(recordingsSessionFolder, tn, 'behav.hdf5');
       if ~isfile(rf)
           fprintf('Unable to read (%s)\n', rf);
           continue;
       end
       trial_timestamps_ms = double(h5read(rf, '/timestamp_ms'));

       new_timestamps_ms = trial_timestamps_ms + t0;

       session_timestamps_ms = cat(1, session_timestamps_ms, new_timestamps_ms);
    end
end % function
