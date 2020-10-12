close all
clear all
clc


numBits = 32;
trialSeparationSeconds = 10;

arenaLength_cm = 30.0;
arenaWidth_cm = 20.0;
cm_per_bin = 2.0;
gaussian_sigma_cm = 3.0;
gassian_size_cm=30;

dataFolder = pwd;

nvtFilename = fullfile( dataFolder, 'VT1.nvt');
fprintf('Loading position data from (%s) ... ', nvtFilename);
[t_mus, x_px, y_px, ~, ~, ~, ~] = Nlx2MatVT( nvtFilename, [1 1 1 1 1 1], 1, 1, [] );
fprintf('done!\n');
    
tFiles = dir(fullfile(dataFolder, 'TT*.t*'));
numTFiles = length(tFiles);
h = cell(1, numTFiles);
for iFile = 1:numTFiles
    try
        fprintf('Processing %d of %d (%s) ... ', iFile, numTFiles, tFiles(iFile).name);
        tFilename = fullfile( tFiles(iFile).folder, tFiles(iFile).name );
        h{iFile} = ml_nlx_auto_placemaps(tFilename, t_mus, x_px, y_px, trialSeparationSeconds, numBits, ...
            arenaLength_cm, arenaWidth_cm, cm_per_bin, gaussian_sigma_cm, gassian_size_cm);
        fprintf('done!\n');
    catch e
        fprintf('Error.\n');
        disp(e)
    end
end
