close all
clear all
clc

%nvtFullFilename = fullfile(pwd, 'VT1.nvt');
[filename, pathname] = uigetfile({'*.nvt', 'Neuralynx Video Tracker (*.nvt)'}, 'Pick a file', pwd);
nvtFullFilename = fullfile(pathname, filename);

CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S = 10;
    
numTrials = ml_nlx_nvt_get_num_trials(nvtFullFilename, CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S);

h1 = figure();
p = 4; q = 4; k = 1;
for iTrial = 1:numTrials
    %h1 = figure(h1)
    figure(h1)
    ax(k) = subplot(p,q,k);
    k = k + 1;
    
    [ts_ms, x_px, y_px, theta_deg] =  ml_nlx_nvt_get_raw_trial(iTrial, nvtFullFilename, CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S);

    plot(x_px, y_px, 'm.');
    
    hold on
 
    axis equal
    grid on
    set(gca, 'ydir', 'reverse')
    
    h2 = figure();
    subplot(3,1,1)
    plot(ts_ms, x_px, 'r.-')
    subplot(3,1,2)
    plot(ts_ms, y_px, 'b.-')
    subplot(3,1,3)
    plot(ts_ms, theta_deg, 'k-')
    

end
linkaxes(ax, 'xy')


