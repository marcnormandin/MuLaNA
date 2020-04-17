%% Load data
close all
clear all
clc

nvtFilename = 'VT1.nvt';
nvt_file_trial_separation_threshold_s = 10;

trials = ml_nlx_nvt_split_into_trials( nvtFilename, nvt_file_trial_separation_threshold_s );

%%

% I only have image for trial 1
iTrial = 1;
trial = trials{iTrial};

% background image
bgi = imread('TR1.png');

bgiResolutionX = size(bgi,2);
bgiResolutionY = size(bgi,1);

% Defaults
nvtResolutionX = []; % 720, read from nvt
nvtResolutionY = []; % 480, read from nvt

% Extract the resolution from the nvt data so that we
% don't assume that it is constant.
h = trial.header;
for i = 1:length(h)
    s = h{i};
    key = '-Resolution';
    
    if length(s) >= length(key)
        if strcmp(s(1:length(key)), '-Resolution')
            fprintf('%s\n', s);
            t = strip(s);
            t = split(t, ' ');
            nvtResolutionX = str2double(t{2});
            nvtResolutionY = str2double(t{3});
        end
    end
end

% We need to offset the values (form a uniform margin)
offsetX = -(nvtResolutionX - bgiResolutionX)/2;
offsetY = -(nvtResolutionY - bgiResolutionY)/2;

x = trial.extractedX + offsetX;
y = trial.extractedY + offsetY;

%% Plot
close all
figure
imshow(bgi);
hold on
plot(x,y,'g.','markerfacecolor', 'g')
