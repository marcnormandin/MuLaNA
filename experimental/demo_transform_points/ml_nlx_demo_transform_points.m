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

% Plot
p = 1; q = 2; k = 1;
figure

subplot(p,q,k)
k = k + 1;
plot(x_px, y_px, 'k.')
set(gca, 'ydir', 'reverse')
axis equal

subplot(p,q,k)
k = k + 1;
plot(x_cm, y_cm, 'b.')
set(gca, 'ydir', 'reverse')
axis equal
