close all
clear all
clc

fl = dir(fullfile(pwd, 'trial*_arenaroi.mat'));
numTrials = length(fl);

for iTrial = 1:numTrials
    s = split(fl(iTrial).name, '.');
    fprintf('Converting %s to h5\n', s{1});
    
    outputFilename = fullfile(fl(iTrial).folder, sprintf('%s.h5', s{1}));
    if isfile(outputFilename)
        delete(outputFilename)
    end

    x = load(fullfile(fl(iTrial).folder, fl(iTrial).name));
    
    numVertices = 4;
    
    h5create(outputFilename, '/xVertices', [numVertices]);
    h5write(outputFilename, '/xVertices', x.arenaroi.xVertices);
    
    h5create(outputFilename, '/yVertices', [numVertices]);
    h5write(outputFilename, '/yVertices', x.arenaroi.yVertices)
end

%     outputFilename = fullfile(fl{iTrial}.folder, fl{iTrial}.name);
% 
%     numSamples = length(ExtractedX);
% 
%     if isfile(outputFilename)
%         delete(outputFilename)
%     end
% 
%     h5create(outputFilename, '/x', [numSamples]);
%     h5write(outputFilename, '/x', ExtractedX);
% 
%     h5create(outputFilename, '/y', [numSamples]);
%     h5write(outputFilename, '/y', ExtractedY);
% 
%     h5create(outputFilename, '/t', [numSamples]);
%     h5write(outputFilename, '/t', TimeStamps);
% 
%     h5create(outputFilename, '/angle', [numSamples]);
%     h5write(outputFilename, '/angle', ExtractedAngle);
