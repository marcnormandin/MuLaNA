function [t_ms, x_px, y_px, theta_deg] =  ml_nlx_nvt_get_raw_trial(iTrial, nvtFullFilename, CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S)
    % Load the nvt file and split it into trials
    %nvtFullFilename = fullfile(pwd, 'VT1.nvt');
    %CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S = 100;
    nvtTrials = ml_nlx_nvt_split_into_trials( nvtFullFilename, CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S );
    
    numTrials = length(nvtTrials);
    if numTrials < iTrial || iTrial < 1
        error('The requested trial number (%d) is outside the range 1 to %d.', iTrial, numTrials);
    end
    trial = nvtTrials{iTrial};

    t_ms = trial.timeStamps_mus / 10^3;
    x_px = trial.extractedX;
    y_px = trial.extractedY;
    theta_deg = trial.extractedAngle;
end % function
