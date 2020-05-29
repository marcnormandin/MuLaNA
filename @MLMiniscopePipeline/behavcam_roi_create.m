function behavcam_roi_create( obj, session, trial )
    % Ask the user to define the ROI
    [pROI] = ml_cai_behavcam_roi_create( trial.getAnalysisDirectory(), 'verbose', obj.isVerbose(), 'includeOtherROI', obj.Config.includeOtherRoi==1 );

    save(fullfile(trial.getAnalysisDirectory(), 'pROI.mat'), 'pROI');
end % function