close all
clear all
clc

nvtFullFilename = fullfile(pwd, 'VT1.nvt');
CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S = 10;
    
numTrials = ml_nlx_nvt_get_num_trials(nvtFullFilename, CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S);

figure
p = 4; q = 6; k = 1;
for iTrial = 1:numTrials
    
    
    [t_ms, x_px, y_px, theta_deg] =  ml_nlx_nvt_get_raw_trial(iTrial, nvtFullFilename, CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S);

    % Find and remove the (0,0) values since they aren't useful.
    zeroIndices = union(find(x_px == 0), find(y_px==0));
    x_px(zeroIndices) = [];
    y_px(zeroIndices) = [];
    t_ms(zeroIndices) = [];
    theta_deg(zeroIndices) = [];
    
%     h1 = plot(x_px, y_px, 'm.');
%     
%     hold on

    % Compute the convex hull
    use_hull = true;
    if use_hull
        K1 = convhull(x_px, y_px);
        x_hull = x_px(K1);
        y_hull = y_px(K1);
        fprintf('Using the hull to calculate the components\n');
    else
        x_hull = x_px;
        y_hull = y_px;
    end
    
    m_x = mean(x_px);
    m_y = mean(y_px);
    x = x_px - m_x;
    y = y_px - m_y;
    lx = max(x) - min(x);
    ly = max(y) - min(y);
    
    
    % Perform PCA to find the principal axes
    X = [x_hull', y_hull'];
    C = pca(X)
    
    ax(k) = subplot(p,q,k);
    k = k + 1;
    
        plot(x, y, 'k.')
        hold on
        plot([0, C(1,1)*lx/2], [0, ly*C(1,2)/2], 'r-', 'linewidth', 4)
        plot([0, C(2,1)*lx/2], [0, ly*C(2,2)/2], 'g-', 'linewidth', 4)
        axis equal tight
    grid on
    grid minor
%     set(gca, 'ydir', 'reverse')
    title(sprintf('Trial %d', iTrial))
    
    ax(k) = subplot(p,q,k);
    k = k + 1;
    %pr = zeros(size(X));
    pr = [];
    XP = [x', y'];
    for iP = 1:length(x)
        pr(iP,2) = dot(XP(iP,:), [C(1,1), C(1,2)]');
        pr(iP,1) = dot(XP(iP,:), [C(2,1), C(2,2)]');
    end
    plot(pr(:,1), pr(:,2), 'm.')
    
    axis equal tight
    grid on
    grid minor
%     set(gca, 'ydir', 'reverse')
    title(sprintf('Trial %d', iTrial))
end
%linkaxes(ax, 'xy')
