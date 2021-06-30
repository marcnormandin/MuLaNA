close all
clear all
clc

% The freezeframe videos don't seem to record the frame rate at which they
% were recorded so set this to what it should be.
frameRate_hz = 15;

% Select a folder that contains the video
msg = 'Select the folder containing the FreezeFrame-formatted videos';
fprintf('%s\n\n', msg);

numErrors = 0;
numExported = 0;

inputFolder = uigetdir(pwd, msg);
if inputFolder ~= 0
    fileList = dir(fullfile(inputFolder, '*.ffii'));
    fprintf('Found %d files to be exported.\n\n', length(fileList));
    numFreezeframeVideos = length(fileList);
    
    for i = 1:length(fileList)
        freezeframeFilename = fullfile(fileList(i).folder, fileList(i).name);
        fprintf('Exporting the FreezeFrame file (%s) ...\n', freezeframeFilename);
   
        try
            exportedFilename = ml_freezeframe_export_video(freezeframeFilename, frameRate_hz);
            fprintf('\tExported file saved (%s)\n\n', exportedFilename);
            numExported = numExported + 1;
        catch e
            msgText = getReport(e);
            numErrors = numErrors + 1;
        end
    end
else
    fprintf('No folder selected.\n');
end

fprintf('\n\n');
fprintf('%d of %d FreezeFrame videos were exported to standard video format.\n', numExported, numFreezeframeVideos);
fprintf('%d errors were encountered.\n', numErrors);
fprintf('End of program.\n\n');
