close all
clear all
clc

%% Load the data (it doesn't matter how)
tmp = load('/work/muzziolab/PROJECTS/two_contexts_CA1/tetrodes/recordings/feature_rich/AK42_CA1/d7/trial_3_arenaroi.mat');
arenaroi = tmp.arenaroi;

tmp = load('/work/muzziolab/PROJECTS/two_contexts_CA1/tetrodes/analysis/feature_rich/AK42_CA1/d7/trial_3_nvt.mat');
trial = tmp.trial;

clear tmp

x_px = trial.extractedX;
y_px = trial.extractedY;
a_px = trial.extractedAngle;

% Remove the zeros
zeroIndices = find(x_px == 0 & y_px == 0);
x_px(zeroIndices) = [];
y_px(zeroIndices) = [];
a_px(zeroIndices) = [];

%%
x_length_cm = 20.0;
y_length_cm = 30.0;

referencePointsVideo = nan(2,4);
referencePointsVideo(1,:) = reshape(arenaroi.xVertices, 1, 4);
referencePointsVideo(2,:) = reshape(arenaroi.yVertices, 1, 4);

referencePointsCanon = nan(2,4);
referencePointsCanon(1,:) = [x_length_cm, 0, 0, x_length_cm];
referencePointsCanon(2,:) = [0, 0, y_length_cm, y_length_cm];    
        
% Get the transformation matrix
vtrans = homography_solve([referencePointsVideo(1,:); referencePointsVideo(2,:)], [referencePointsCanon(1,:); referencePointsCanon(2,:)]);

% Tranform the points into the new coordinate system
canonPts = homography_transform([x_px; y_px], vtrans);
x_cm = canonPts(1,:);
y_cm = canonPts(2,:);

% Compute angle of the feature (from right to left) in video coordinates
angle_px = atan2( referencePointsVideo(2,2) - referencePointsVideo(2,1), referencePointsVideo(1,2) - referencePointsVideo(1,1) );
angle_px( angle_px < pi ) = angle_px( angle_px < pi ) + 2*pi;
angle_px = angle_px * 360 / (2*pi)

% Compute angle of the feature (from right to left) in standard coordinates
angle_cm = atan2( referencePointsCanon(2,2) - referencePointsCanon(2,1), referencePointsCanon(1,2) - referencePointsCanon(1,1) );
angle_cm( angle_cm < pi ) = angle_cm( angle_cm < pi ) + 2*pi;
angle_cm = angle_cm * 360 / (2*pi)

% Now compute what the difference is
angleDifference = angle_cm - angle_px

% Add the difference to the angle in video coordinates to get the angle in
% standard coordinates
a_cm = a_px + angleDifference;

colours = linspace(0,4,4);

% Length of direction vector to show for plotting
F_px = 30;
F_cm = 5;

close all

figure
for i = 1:1000
    subplot(1,2,1)
    plot(x_px(i), y_px(i), 'bo', 'markerfacecolor', 'b', 'markersize', 10)
    set(gca, 'ydir', 'reverse')
    grid on
    title('Video Coordinates')
    hold on
    plot([x_px(i) x_px(i) + F_px * cosd(a_px(i))], [y_px(i), y_px(i) + F_px * sind(a_px(i))], 'r-', 'linewidth', 5);
    %quiver(x_px(i), y_px(i), F_px * cosd(a_px(i)), F_px * sind(a_px(i)), 'r-', 'linewidth', 2);

    scatter(referencePointsVideo(1,:), referencePointsVideo(2,:), 50, colours, 'filled')
    colormap jet
    hold off
    xlim([min(x_px), max(x_px)])
    ylim([min(y_px), max(y_px)])
    
    subplot(1,2,2)
    plot(x_cm(i), y_cm(i), 'bo', 'markerfacecolor', 'b', 'markersize', 10)
    set(gca, 'ydir', 'reverse')
    grid on
    title('Standard Coordinates')
    hold on
    plot([x_cm(i) x_cm(i) + F_cm * cosd(a_cm(i))], [y_cm(i), y_cm(i) + F_cm * sind(a_cm(i))], 'r-', 'linewidth', 5);
    scatter(referencePointsCanon(1,:), referencePointsCanon(2,:), 50, colours, 'filled')
    colormap jet
    hold off
    xlim([min(x_cm), max(x_cm)])
    ylim([min(y_cm), max(y_cm)])
    
    pause(1)
end % loop
