close all
clear all
clc
% 's2', 's4', 's6', 
sessionNames = {'s7', 's8', 's9', 's10', 's11'};
numSessions = length(sessionNames);
q = 1:3;
avc1n = zeros(numSessions, length(q));
avc2n = zeros(numSessions, length(q));

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
        avc1n(iSession,:) = [];
        avc2n(iSession,:) = [];
        continue
    end
    
    avc1 = sum(MFRT(q,1:2:numTrials-2),2);
    avc2 = sum(MFRT(q,2:2:numTrials-2),2);
    angleDegAverage = acos(dot(avc1,avc2) ./ (norm(avc1) * norm(avc2))) * 360 / (2*pi);
    cosOfAverageAngle = dot(avc1,avc2) ./ (norm(avc1) * norm(avc2))
    
    avc1n(iSession,:) = avc1 ./ norm(avc1);
    avc2n(iSession,:) = avc2 ./ norm(avc2);
    

    
    fprintf('Session ( %s ) average vector angle between contexts = %f degrees\n', sessionName, angleDegAverage);

    % Now compute the direction for the last two trials
    lvc1n = MFRT(q,numTrials-1);
    lvc1n = lvc1n ./ norm(lvc1n);
    
    lvc2n = MFRT(q,numTrials);
    lvc2n = lvc2n ./ norm(lvc2n);
    
    
    % Predict the second last trial
    lvc1n_avc1n = dot(lvc1n, avc1n(iSession,:));
    lvc1n_avc2n = dot(lvc1n, avc2n(iSession,:));
    
    if lvc1n_avc1n < lvc1n_avc2n
        fprintf('Correct context prediction for trial %d!\n', numTrials-1);
    else
        fprintf('Incorrect context prediction for trial %d...\n', numTrials-1);
    end
    
    % Predict the last trial
    lvc2n_avc1n = dot(lvc2n, avc1n(iSession,:));
    lvc2n_avc2n = dot(lvc2n, avc2n(iSession,:));
    
    if lvc2n_avc2n < lvc2n_avc1n
        fprintf('Correct context prediction for trial %d!\n', numTrials);
    else
        fprintf('Incorrect context prediction for trial %d...\n', numTrials);
    end

    fprintf('\n\n')
end

figure
sphere
hold on
plot3(avc1n(:,1), avc1n(:,2), avc1n(:,3), 'ko', 'markerfacecolor', 'r');
hold on
plot3(avc2n(:,1), avc2n(:,2), avc2n(:,3), 'ks', 'markerfacecolor', 'b');
grid on
axis equal square

figure
%sphere
%hold on
colours = {'r', 'g', 'b', 'm', 'y', 'k', 'r', 'g', 'b', 'm', 'y'};
for iSession = 1:numSessions
    c = colours{iSession};
    plot3([0, avc1n(iSession,1)], [0, avc1n(iSession,2)], [0, avc1n(iSession,3)], sprintf('%so-', colours{iSession}), 'markerfacecolor', c);
    hold on
    plot3([0, avc2n(iSession,1)], [0, avc2n(iSession,2)], [0, avc2n(iSession,3)], sprintf('%so:', colours{iSession}), 'markerfacecolor', c);
    grid on
end
%legend(sprintf('%s',1:numSessions))
axis equal square