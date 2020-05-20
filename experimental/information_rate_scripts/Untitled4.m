close all
clear all
clc

sessionNames = {'s2', 's3', 's4', 's6', 's7', 's8', 's9', 's10', 's11'};
numSessions = length(sessionNames);
%avc1n = cell(1,numSessions);
%avc2n = cell(1,numSessions);

for iSession = 1:length(sessionNames)
    tfolder = fullfile('analysis', 'chengs_task_2c', sessionNames{iSession});
    %x = readtable(fullfile(tfolder, 'pfStats.xlsx'));
    sessionName = sessionNames{iSession};
    
    %x = xlsread(fullfile(tfolder, 'pfStats.xlsx'), sprintf('%s_meanFiringRate', sessionName));
    %x = xlsread(fullfile(tfolder, 'pfStats.xlsx'), sprintf('%s_peakFiringRate', sessionName));

    x = xlsread(fullfile(tfolder, 'pfStats.xlsx'), sprintf('%s_informationRate', sessionName));
    %x = xlsread(fullfile(tfolder, 'pfStats.xlsx'), sprintf('%s_informationPerSpike', sessionName));

    MFRT = x(2:end, 2:end);
    numTrials = size(MFRT,1);
    numCells = size(MFRT,2);
    MFRT = MFRT';
    
    if isempty(MFRT)
        continue
    end
    
    avc1 = sum(MFRT(:,1:2:numTrials-2),2);
    avc2 = sum(MFRT(:,2:2:numTrials-2),2);
    angleDegAverage = acos(dot(avc1,avc2) ./ (norm(avc1) * norm(avc2))) * 360 / (2*pi);
    
    avc1n = avc1 ./ norm(avc1);
    avc2n = avc2 ./ norm(avc2);
    
    % Now compute the direction for the last two trials
    
    lvc1n = MFRT(:,numTrials-1);
    lvc1n = lvc1n ./ norm(lvc1n);
    
    lvc2n = MFRT(:,numTrials);
    lvc2n = lvc2n ./ norm(lvc2n);
    
    % Now see which contexts best match the last two trials
    lvc1n_avc1n = dot(lvc1n, avc1n);
    lvc1n_avc2n = dot(lvc1n, avc2n);
    
    fprintf('Session ( %s ) average vector angle between contexts = %f degrees\n', sessionName, angleDegAverage);

    if lvc1n_avc1n < lvc1n_avc2n
        fprintf('Correct context prediction for trial %d!\n', numTrials-1);
    else
        fprintf('Incorrect context prediction for trial %d...\n', numTrials-1);
    end
        
    lvc2n_avc1n = abs(dot(lvc2n, avc1n));
    lvc2n_avc2n = abs(dot(lvc2n, avc2n));
    
    if lvc2n_avc2n < lvc2n_avc1n
        fprintf('Correct context prediction for trial %d!\n', numTrials);
    else
        fprintf('Incorrect context prediction for trial %d...\n', numTrials);
    end

    fprintf('\n\n')
end

