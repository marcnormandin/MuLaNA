function [expJson] = mlgp_read_experiment_description_json(expJsonFilename)
    expJson = ml_util_json_read(expJsonFilename);
    
    % Validate
    
    % Check of the field exists
    fieldNames = fields(expJson);
    if ~ismember(fieldNames, 'apparatus_type')
        error('The field ''apparatus_type'' does not exist in (%s). Its value must be one of the following values: ''neuralynx_tetrodes'', or ''ucla_miniscope''', expJsonFilename);
    end
    
    if ~ismember(expJson.apparatus_type, {'neuralynx_tetrodes', 'ucla_miniscope'})
        error('The field ''apparatus_type'' in (%s) must be one of the following values: ''neuralynx_tetrodes'', or ''ucla_miniscope''', expJsonFilename);
    end
    
    if ~ismember(fields(expJson), 'num_contexts')
        expJson.num_contexts = 1;
        warning('The field ''num_contexts'' does not exist in (%s). Setting it to the default value of (%d).', expJsonFilename, expJson.num_contexts);
    end
    
    if ~ismember(fields(expJson), 'has_digs')
        expJson.has_digs = 0;
        warning('The field ''has_digs'' does not exist in (%s). Setting it to the default value of (%d).', expJsonFilename, expJson.has_digs);
    end
    
    % check that the specified session directories exist
    if ~ismember(fields(expJson), 'session_folders')
        error('The field ''session_folders'' does not exist in (%s). It must be specified. e.g. "session_folder": ["s1", "s2", "s3"].', expJsonFilename);
    end
    
    if strcmpi(expJson.apparatus_type, 'neuralynx_tetrodes')
        if ~ismember(fields(expJson), 'nvt_filename')
            expJson.nvt_filename = 'VT1.nvt';
            warning('The field ''nvt_filename'' does not exist in (%s). Setting it to the default value (%s).', expJsonFilename, expJson.nvt_filename);
        end
        
        if ~ismember(fields(expJson), 'nvt_file_trial_separation_threshold_s')
            expJson.nvt_file_trial_separation_threshold_s = 10.0;
            warning('The field ''nvt_file_trial_separation_threshold_s'' does not exist in (%s). Setting it to the default value (%d).', expJsonFilename, expJson.nvt_file_trial_separation_threshold_s);
        end
        
        if ~ismember(fields(expJson), 'mclust_tfile_bits')
            expJson.mclust_tfile_bits = -1;
            warning('The field ''mclust_tfile_bits'' does not exist in (%s). Setting it to the default value (%d).', expJsonFilename, expJson.mclust_tfile_bits);
        end
    elseif strcmp(expJson.apparatus_type, 'ucla_miniscope')
        % Nothing specific
    end
    
    
    if ~ismember(fields(expJson), 'imaging_region')
        expJson.imaging_region = 'unspecified';
        warning('The field ''imaging_region'' does not exist in (%s). Setting it to the default value (%d).', expJsonFilename, expJson.imaging_region);
    end
    
    if ~ismember(fields(expJson), 'animal')
        expJson.animal = 'unspecified';
        warning('The field ''animal'' does not exist in (%s). Setting it to the default value (%d).', expJsonFilename, expJson.animal);
    end
    
    if ~ismember(fields(expJson), 'experiment')
        expJson.experiment = 'unspecified';
        warning('The field ''experiment'' does not exist in (%s). Setting it to the default value (%d).', expJsonFilename, expJson.experiment);
    end
    
    if ~ismember(fields(expJson), 'arena')
        expJson.arena.shape = "rectangle";
        expJson.arena.x_length_cm = 20.0;
        expJson.arena.y_length_cm = 30.0;
        warning('The field ''arena'' does not exist in (%s). Setting it to the default of a 20cm x 30cm rectangle.', expJsonFilename);
    end
end % function