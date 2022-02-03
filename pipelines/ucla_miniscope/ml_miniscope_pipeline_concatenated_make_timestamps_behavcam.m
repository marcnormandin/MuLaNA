%% Read in each trial's timestamp.dat file and then write to a new combined timestamp.dat file.
function ml_miniscope_pipeline_concatenated_make_timestamps_behavcam(session)
    scopeTimes = {};
    numTrials = session.getNumTrials();

    for iTrial = 1:numTrials
        trial = session.getTrial(iTrial);
        c = trial.getTimeString();
        s = split(c, '_');

        % trial start time
        t0 = str2num(s{1}(2:end)) * 60 * 60;
        t0 = t0 + str2num(s{2}(2:end)) * 60;
        t0 = t0 + str2num(s{3}(2:end));
        t0 = t0 * 1000.0;

        %tr = ml_cai_trialresult_read(  );
        scopeDataset  = ml_cai_scope_h5_read( fullfile(trial.getAnalysisDirectory(), "behav.hdf5") );
        st = scopeDataset.timestamp_ms + t0;

        scopeTimes{iTrial} = st;
    end

    numFrames = zeros(1, numTrials);
    for iTrial = 1:numTrials
        numFrames(iTrial) = length(scopeTimes{iTrial});
    end

    combinedTimes = [];
    for iTrial = 1:numTrials
        st = scopeTimes{iTrial};
        if isempty(combinedTimes)
            combinedTimes = st;
        else
            combinedTimes = cat(1, combinedTimes, st);
        end
    end

    
    
    % Save
    % Timestamps.dat file will be saved here
    sessionDirectorySep = session.getSessionDirectory();
    sessionDirectoryCat = strrep(sessionDirectorySep, '_sep', '_cat');
    destVideoFolder = fullfile(sessionDirectoryCat, 'H1_M1_S1'); % We will create a single trial
    if ~exist(destVideoFolder, 'dir')
        mkdir(destVideoFolder);
    end
    
%     % Copy the settings_and_notes.dat file from trial 1 to the new trial
%     % directory which just serves as a dummy file because some of the CNMFe
%     % code requires that it exist.
%     sanFilename = fullfile(trial.getTrialDirectory(), 'settings_and_notes.dat');
%     if ~isfile(sanFilename)
%         error('The recording data is missing the file (%s).\n', sanFilename);
%     end
%     sanFilenameOut = fullfile(destVideoFolder, 'settings_and_notes.dat');
%     if isfile(sanFilenameOut)
%         delete(sanFilenameOut);
%     end
%     copyfile(sanFilename, sanFilenameOut);
%     fprintf('Copied (%s) to (%s) as a dummy placeholder.\n', sanFilename, sanFilenameOut);
    
    scopeTimes = combinedTimes;
    
    % Now save the concatenated timestamps file
    destTimestampFilename = fullfile(destVideoFolder, 'timestamp_behav.dat');
    fid = fopen(destTimestampFilename, 'w');
    fprintf(fid, sprintf('%s\t%s\t%s\t%s\n', 'camNum','frameNum','sysClock','buffer'));
    numTimesamples = length(scopeTimes);
    for iTime = 1:numTimesamples
        fprintf(fid, '%d\t%d\t%d\t%d', 1, iTime, scopeTimes(iTime), 1);
        
        if iTime < numTimesamples
            fprintf(fid, '\n');
        end
    end
    fclose(fid);
    fprintf('Finished saving concatenated timestamps to file: %s\n', destTimestampFilename);
    
end % function