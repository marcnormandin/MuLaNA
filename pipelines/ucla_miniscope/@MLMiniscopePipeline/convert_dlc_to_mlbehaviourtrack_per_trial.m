function convert_dlc_to_mlbehaviourtrack_per_trial( obj, session, trial )
    % Track the behaviour
    mlvidrec = MLVideoRecord( fullfile(trial.getAnalysisDirectory(), 'behav.hdf5') );

    % For now the DLC data is put into the recording folder (but
    % shouldn't be)
    %trialDLCFolder = trial.rawFolder;
    trialDLCFolder = strrep(trial.getTrialDirectory(), 'recordings', 'dlc_tracks');

    % Perform the main conversion
   % track = ml_cai_dlc_to_mlbehaviourtrack_with_heading(trialDLCFolder, mlvidrec.timestamp_ms);
    track = ml_cai_dlc_to_mlbehaviourtrack(trialDLCFolder, mlvidrec.timestamp_ms);

    % Save the track
    outputFilename = fullfile(trial.getAnalysisDirectory(), 'behav_track_vid.hdf5');
    if isfile(outputFilename)
        fprintf('Removing previous track ( %s ) ... ', outputFilename);
        delete(outputFilename)
        fprintf('done!\n');
    end
    track.save(outputFilename);


    % Make a plot of the track as a diagnostic
    h = figure;
    imshow(imadjust(rgb2gray(imread(fullfile(trial.getAnalysisDirectory(), 'behavcam_background_frame.png')))))
    hold on
    plot(track.pos(:,1), track.pos(:,2), 'b.-')
    saveas(h, fullfile(trial.getAnalysisDirectory(), 'behavcam_track_pos.png'));
    close(h);
end