close all
clear all
clc

nvtFullFilename = fullfile(pwd, 'VT1.nvt');
CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S = 10;
    
numTrials = ml_nlx_nvt_get_num_trials(nvtFullFilename, CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S);

figure
p = 4; q = 4; k = 1;
for iTrial = 1:numTrials
    ax(k) = subplot(p,q,k);
    k = k + 1;
    
    [t_ms, x_px, y_px, theta_deg] =  ml_nlx_nvt_get_raw_trial(iTrial, nvtFullFilename, CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S);

    h1 = plot(x_px, y_px, 'm.');
    
    hold on
 
    axis equal
    grid on
    set(gca, 'ydir', 'reverse')
end
linkaxes(ax, 'xy')


