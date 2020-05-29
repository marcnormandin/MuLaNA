function scopecam_cnmfe_run( obj, session, trial )
    %Remove any previous results otherwise it requires user interaction
    oldCnmfeFolder = fullfile(trial.getAnalysisDirectory(), 'msaligned_source_extraction');
    if isfolder(oldCnmfeFolder)
       rmdir(oldCnmfeFolder, 's');
    end

    % Run the CNMFE
    mlvidrecScope = MLVideoRecord(fullfile(trial.getAnalysisDirectory(), 'scope.hdf5'));
    %cnmfeOptions = men_cnmfe_options_create('framesPerSecond', mlvidrecScope.videoFramesPerSecond, 'verbose', obj.verbose);
    obj.CnmfeOptions.Fs = mlvidrecScope.videoFramesPerSecond;
    % The CNMFe uses the 'msaligned' video which is saved by a
    % previous phase into the 'analysis' folder

    alignedScopeFilenameFull = fullfile(trial.getAnalysisDirectory(), 'msaligned.avi');
    [cnmfe, pCnmfe] = ml_cai_cnmfe_compute( obj.CnmfeOptions, alignedScopeFilenameFull, 'verbose', obj.isVerbose() );
    save(fullfile(trial.getAnalysisDirectory(), 'cnmfe.mat'),'-v7.3', 'cnmfe');
    save(fullfile(trial.getAnalysisDirectory(), 'pCnmfe'), '-v7.3', 'pCnmfe');
end