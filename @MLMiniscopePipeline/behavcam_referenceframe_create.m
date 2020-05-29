function behavcam_referenceframe_create( obj, session, trial )
    % Compute the background frame to present to the user and use for the
    % tracker
    [pRef] = ml_cai_behavcam_referenceframe_create( trial.getTrialDirectory(), trial.getAnalysisDirectory(), ...
        'verbose', obj.isVerbose(), 'maxFramesToUse', obj.Config.behaviour_camera.background_frame.max_frames_to_use );

    save(fullfile(trial.getAnalysisDirectory(), 'pRef.mat'), 'pRef');
end % function