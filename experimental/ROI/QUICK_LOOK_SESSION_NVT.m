%function asdfadf()

close all
clear all
clc

%global x_px
%global y_px

global h1 h2

nvtFullFilename = fullfile(pwd, 'VT1.nvt');
CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S = 100;
    
numTrials = ml_nlx_nvt_get_num_trials(nvtFullFilename, CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S);


    
figure
p = 3; q = 4; k = 1;
for iTrial = 1:1
    %ax(k) = subplot(p,q,k);
    k = k + 1;
        [t_ms, x_px, y_px, theta_deg] =  ml_nlx_nvt_get_raw_trial(iTrial, nvtFullFilename, CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S);

    h1 = plot(x_px, y_px, 'm.');
    %[xx,yy,indx,sect] = graphpoints();
    %h = histogram2(x_px,y_px,100,'DisplayStyle','tile','ShowEmptyBins','off');
    hold on
    %[t_ms, x_px, y_px, theta_deg] =  ml_nlx_nvt_get_filtered_trial(iTrial, nvtFullFilename, CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S);
    %plot(x_px, y_px, 'r.')
    axis equal
    grid on
    set(gca, 'ydir', 'reverse')
    
    roi = images.roi.Rectangle();
    roi.draw();
    %addlistener(roi,'ROIMoved',@allevents);
    
    insidei = inROI(roi,x_px,y_px);
   
    %inFloor = inpolygon(x_px,y_px, roi.insid, roi.inside.i);
    %inFloorI = iq(inFloor);
    %h1 = plot(x_px, y_px, 'b.');
    hold on
    xx = x_px(find(insidei == 1));
    yy = y_px(find(insidei == 1));
    h2 = plot(xx,yy,'ro');
    
    tmp = load(sprintf('trial_%d_arenaroi.mat', iTrial));
    h3 = plot(tmp.arenaroi.xVertices, tmp.arenaroi.yVertices, 'ko', 'markerfacecolor', 'k');
    P1= [tmp.arenaroi.xVertices(1) tmp.arenaroi.yVertices(1)];
    P2= [tmp.arenaroi.xVertices(2) tmp.arenaroi.yVertices(2)];
    D = P2 - P1;
    quiver( P1(1), P1(2), D(1), D(2), 0, 'r','linewidth',4 )

    %roiBounds = images.roi.Polygon(gca, 'Position', [tmp.arenaroi.xVertices(:), tmp.arenaroi.yVertices]);
    %roiBounds.draw()
    roiBounds = drawpolygon(gca, 'Position', [tmp.arenaroi.xVertices(:), tmp.arenaroi.yVertices]);

    addlistener(roi,'MovingROI',@(src, evt) roiChange(src, evt, x_px, y_px, roi, h1, h2));

    
end
%linkaxes(ax, 'xy')
%end % function

