function split_into_trials(obj)
    nvtFullFilename = fullfile(obj.dataFolder, obj.CONFIG_NVT_FILENAME);
    if ~isfile(nvtFullFilename)
        error('The nvt file does not exist: %s\n', nvtFullFilename);
    end
    
    % Load the nvt file and split it into trials
    trials = ml_nlx_nvt_split_into_trials( nvtFullFilename, obj.CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S );
    
    if ~isfolder(obj.resultsFolder)
        mkdir(obj.resultsFolder);
    end
    
    % Save each trial's data as a separate mat filename
    obj.numTrialsRecorded = length(trials);
    for iTrial = 1:obj.numTrialsRecorded
        trial = trials{iTrial};
        trialNvtFilename = fullfile(obj.resultsFolder, sprintf('trial_%d_nvt.mat', iTrial));
        if obj.verbose
            fprintf('Saving %s... ', trialNvtFilename);
        end
        save(trialNvtFilename, 'trial');
        if obj.verbose
            fprintf('done!\n');
        end
    end
end
