function [numTrials] = ml_nlx_nvt_get_num_trials(nvtFullFilename, CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S)
    % Load the nvt file and split it into trials
    %nvtFullFilename = fullfile(pwd, 'VT1.nvt');
    %CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S = 100;
    nvtTrials = ml_nlx_nvt_split_into_trials( nvtFullFilename, CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S );
    numTrials = length(nvtTrials);
end % function
