close all
clear all
clc

sessionNames = {'s2', 's3', 's4', 's6', 's7', 's8', 's9', 's10', 's11'};
for iSessionName = 1:length(sessionNames)
    tfolder = fullfile('analysis','chengs_task_2c', sessionNames{iSessionName});
    %x = readtable(fullfile(tfolder, 'pfStats.xlsx'));
    sessionName = sessionNames{iSessionName};
    x = xlsread(fullfile(tfolder, 'pfStats.xlsx'), sprintf('%s_meanFiringRate', sessionName));

    MFRT = x(2:end, 2:end);
    numTrials = size(MFRT,1);
    numCells = size(MFRT,2);
    MFRT = MFRT';
    avc1 = sum(MFRT(:,1:2:numTrials),2);
    avc2 = sum(MFRT(:,2:2:numTrials),2);
    angleDeg = acos(dot(avc1,avc2) ./ (norm(avc1) * norm(avc2))) * 360 / (2*pi);

    fprintf('Session ( %s ) average vector angle between contexts = %f degrees\n', sessionName, angleDeg);
end

