%function asdfadf()

close all
clear all
clc

nvtFullFilename = fullfile(pwd, 'VT1.nvt');
CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S = 10;

numTrials = ml_nlx_nvt_get_num_trials(nvtFullFilename, CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S);
fprintf('num trials = %d\n', numTrials);

 %function asdfadf()

close all
clear all
clc

nvtFullFilename = fullfile(pwd, 'VT1.nvt');
CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S = 10;

numTrials = ml_nlx_nvt_get_num_trials(nvtFullFilename, CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S);
fprintf('num trials = %d\n', numTrials);

 

 %function asdfadf()

close all
clear all
clc

nvtFullFilename = fullfile(pwd, 'VT1.nvt');
CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S = 10;

numTrials = ml_nlx_nvt_get_num_trials(nvtFullFilename, CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S);
fprintf('num trials = %d\n', numTrials);

 
figure
p = 4; q = 4; k = 1;
for iTrial = 1:numTrials
    ax(k) = subplot(p,q,k);
    k = k + 1;
        [t_ms, x_px, y_px, theta_deg] =  ml_nlx_nvt_get_raw_trial(iTrial, nvtFullFilename, CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S);

    badxi = find(x_px == 0);
    badyi = find(y_px == 0);
    badi = intersect(badxi, badyi);
    x_px(badi) = [];
    y_px(badi) = [];
    t_ms(badi) = [];
    theta_deg(badi) = [];
    %subplot(p,q,k);
    h1 = plot(x_px, y_px, 'm.');
    %[xx,yy,indx,sect] = graphpoints();
    %h = histogram2(x_px,y_px,100,'DisplayStyle','tile','ShowEmptyBins','off');
    hold on
    %[t_ms, x_px, y_px, theta_deg] =  ml_nlx_nvt_get_filtered_trial(iTrial, nvtFullFilename, CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S);
    %plot(x_px, y_px, 'r.')
    axis equal
    grid on
    set(gca, 'ydir', 'reverse')
    
end
