% Marc Normandin, 2021
% This demo shows how to smooth the head direction angles using the unwrap
% function and a smoothing function.
close all
clear all
clc

nvt_file_trial_separation_threshold_s = 10;

% Specify a Neuralynx recording folder and NVT file
dataFolder = 'T:\Tinimice\CMG100\Copy_of_CMG100_S3 - Copy';
nvtFilename = fullfile(dataFolder, 'VT1.nvt');

% Load each trial as a separate structure
trialSet = ml_nlx_nvt_split_into_trials( nvtFilename, nvt_file_trial_separation_threshold_s );


%%
iTrial = 1; % Pick a trial from the set

trial = trialSet{iTrial};

% Copy the data to local variables
x = trial.extractedX;
y = trial.extractedY;
t = trial.timeStamps_mus/10^6;
angleDeg = trial.extractedAngle;

% Neuralynx indicates badly acquired values by setting the (x,y) = (0,0) so
% we look for those and then remove them.
badPosi = intersect(find(trial.extractedX==0), find(trial.extractedY==0));
x(badPosi) = [];
y(badPosi) = [];
t(badPosi) = [];
angleDeg(badPosi) = [];

% We will interpolate over a finer spacing in time
dt = 0.001;
st = t(1):dt:t(end);
sx = interp1(t, x, st);
sy = interp1(t, y, st);
sa = interp1(t, angleDeg, st);


% We will smooth by taking a symmetric moving filter
% Window length
WS = round(0.5/dt); 
if mod(WS,2) == 0 % make it odd
    WS = WS + 1;
end

% Convert the angles from [0,360] degrees to [0, 2*pi] radians for the unwrap function.
a = sa * 2*pi/360;

% Unwrap so we can smooth
w = unwrap(a);

% Smooth
wrm = movmedian(w,[WS,WS]);

% Convert the smoothed angles back to [0, 360] degrees
arm = mod(wrm, 2*pi);
drm = rad2deg(arm);

da = 0.5;
[N1,EDGES1] = histcounts(sa, 0:da:359, 'normalization', 'probability');
[N2,EDGES2] = histcounts(drm, 0:da:359, 'normalization', 'probability');

%close all

% Make a polar plot (smoothed)
EDGES1 = EDGES1 * 2*pi/360; % Convert to radian for the plot
EDGES2 = EDGES2 * 2*pi/360;
p = 3;
figure
polarplot(EDGES1(1:end-1), movmedian(N1, [p,p]), 'k-', 'linewidth', 2)
hold on
polarplot(EDGES2(1:end-1), movmedian(N2, [p,p]), 'r-', 'linewidth', 2)

% Make a time series plot of the angles
figure
plot(st, sa, 'k-')
hold on
plot(st, drm, 'r-', 'linewidth', 2);
