close all
clear all
clc

% This code loads an example data set and trial to show the transformation.
% Change these to whatever works for you.
sessionRecordingFolder = 'T:\Tinimice\AK42_CA1\recordings\chengs_task_2c\d7';
sessionAnalysisFolder = 'T:\projects\general_tetrode\analysis\AK42_CA1\chengs_task_two_context\d7';

% Pick a trial
iTrial = 1;

% Load the reference points found in the arenaroi
tmp = load(fullfile(sessionRecordingFolder, sprintf('trial_%d_arenaroi.mat', iTrial)));
arenaroi = tmp.arenaroi;
refP = arenaroi.xVertices;
refQ = arenaroi.yVertices;

% This assumes the typical arena geometry
arenaWidth_cm = 20;
arenaHeight_cm = 30;
refX = [arenaWidth_cm, 0, 0, arenaWidth_cm];
refY = [0, 0, arenaHeight_cm, arenaHeight_cm];

% Get video position data for the trial
tmp = load(fullfile(sessionAnalysisFolder, sprintf('trial_%d_fnvt.mat', iTrial)));
trial = tmp.trial;
x_px = trial.extractedX;
y_px = trial.extractedY;

% Transform to cm
[x_cm, y_cm, vtrans] = ml_core_geometry_homographic_transform_points(refP, refQ, refX, refY, x_px, y_px);

timestamps_ms = trial.timeStamps_mus ./ 10^3;
timestamps_s = timestamps_ms ./ 10^3;

velocity_lowpass_wpass = 0.05;

% Compute the speed
[speed_cm_per_s, speed_smoothed_cm_per_s, vx, vy, vx_smoothed, vy_smoothed] ...
    = ml_core_compute_motion(x_cm, y_cm, timestamps_ms, velocity_lowpass_wpass);

% Plot the position data
p = 1; q = 2; k = 1;
figure
subplot(p,q,k)
k = k + 1;
plot(x_px, y_px, 'k-')
set(gca, 'ydir', 'reverse')
axis equal
title('Video Space (pixels)')
grid on

subplot(p,q,k)
k = k + 1;
plot(x_cm, y_cm, 'b-')
set(gca, 'ydir', 'reverse')
axis equal
title('Canonical Space (cm)')
grid on

% Plot the speed in cm/s
figure
plot(timestamps_s-timestamps_s(1), speed_cm_per_s, 'b-')
hold on
plot(timestamps_s-timestamps_s(1), speed_smoothed_cm_per_s, 'r-', 'linewidth', 2)
legend({'Unsmoothed', 'Smoothed'})
xlabel('Trial Time, t [s]')
ylabel('Speed, s (cm/s)')
title('Speed')
grid on





% Plot the position points coloured by the speed
figure
scatter(x_cm, y_cm, 4, speed_smoothed_cm_per_s, 'filled')
set(gca, 'ydir', 'reverse')
set(gca, 'color', 'k')
axis equal tight
title('Canonical Space (cm)')
grid on
colormap jet
hcb = colorbar;
colorTitleHandle = get(hcb,'Title');
titleString = 'Speed (cm/s)';
set(colorTitleHandle ,'String',titleString);
