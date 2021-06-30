close all
clear all
clc

frameRate_hz = 15;

% Select a video
%limelightFilename = fullfile('C:\Users\fym313\Documents\help_borna_limelight', 'CX3 2523.llii');
%limelightFilename = fullfile('C:\Users\fym313\Documents\help_borna_limelight', 'CX3 2523 Dark.llii');
%limelightFilename = uigetfile();
msg = 'Select the folder containing the Limelight-formatted videos';
fprintf('%s\n\n', msg);

inputFolder = uigetdir(pwd, msg);
if inputFolder ~= 0
    fileList = dir(fullfile(inputFolder, '*.llii'));
    fprintf('Found %d files to be exported.\n\n', length(fileList));
    
    for i = 1:length(fileList)
        limelightFilename = fullfile(fileList(i).folder, fileList(i).name);
        fprintf('Exporting the Limelight file (%s) ...\n', limelightFilename);
   
        try
            exportedFilename = ml_limelight_export_video(limelightFilename, frameRate_hz);
            fprintf('\tExported file saved (%s)\n\n', exportedFilename);
        catch e
            msgText = getReport(e);
        end
    end
else
    fprintf('No folder selected.\n');
end