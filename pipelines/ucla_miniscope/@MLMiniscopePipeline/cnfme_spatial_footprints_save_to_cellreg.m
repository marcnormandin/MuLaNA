function cnfme_spatial_footprints_save_to_cellreg(obj, session, trial)

    cellRegFolder = fullfile(session.getAnalysisDirectory(), obj.Config.cell_registration.session_sfp_output_folder);
    
    % Check if the cellreg folder exists
    if ~isfolder(cellRegFolder)
        mkdir(cellRegFolder);
    end

    cnmfeFilename = fullfile(trial.getAnalysisDirectory(), obj.Config.miniscope_camera.cnmfe.cnmfe_data_filename);
    if ~isfile(cnmfeFilename)
        error('Unable to load the file (%s).\n', cnmfeFilename);
    end

    % this needs to be switchable with ms.mat
    x = load( cnmfeFilename );
    ms = x.cnmfe;
    for cell_i = 1:size(ms.SFPs,3)
        SFP_temp = ms.SFPs(:,:,cell_i);
        SFP_temp(SFP_temp<0.5*max(max(SFP_temp))) = 0; % This is to sharpen footprints, based on Ziv lab method
        SFP(cell_i,:,:) = SFP_temp;
    end

    % Save a copy in the 'cellreg' folder for the session
    sfp_filename = sprintf('%s%0.3d.mat', obj.Config.cell_registration.spatialFootprintFilenamePrefix, trial.getTrialId());
    save( fullfile(cellRegFolder, sfp_filename), 'SFP', '-v7.3'); 

    % Save a copy local to the trial
    save( fullfile(trial.getAnalysisDirectory(), sprintf('%s.mat', obj.Config.cell_registration.spatialFootprintFilenamePrefix)), 'SFP', '-v7.3' );
end
