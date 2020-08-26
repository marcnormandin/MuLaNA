function camerasdat_create( obj, session, trial )
    % Create the camera dat files (TEXT)
    [status, pDat] = ml_cai_daq_camerasdat_create(trial.getTrialDirectory(), 'outputFolder', trial.getAnalysisDirectory(), 'verbose', obj.isVerbose(), 'interactive', false);
    if status ~= 0
        error('Error encountered in call to ml_cai_daq_createcameradataset');
    end
    
    % Fixme! Add date to trials (from session)
   

    % Create the camera video records (HDF5)
    [status, pVid] = ml_cai_daq_videorecords_create(trial.getTrialDirectory(), trial.getAnalysisDirectory(), obj.Experiment.getAnimalName(), obj.Experiment.getExperimentName(), ...
        trial.getDateString(), trial.getTimeString(), 'verbose', obj.isVerbose());
    if status ~= 0
        error('Error encountered in call to ml_cai_videorecordscreate');
    end

    save(fullfile(trial.getAnalysisDirectory(), 'pDat.mat'), 'pDat');
    save(fullfile(trial.getAnalysisDirectory(), 'pVid.mat'), 'pVid');
end