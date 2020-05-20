close all
clear all
clc

% FOR MH1_DH
%sessionNum = 7;
%sessionName = sprintf('s%d', sessionNum);

sessionNum = 7;
sessionName = sprintf('d%d', sessionNum);

tfolder = fullfile('analysis', 'chengs_task_2c', sessionName);
%x = readtable(fullfile(tfolder, 'pfStats.xlsx'));
mfrt = xlsread(fullfile(tfolder, 'pfStats.xlsx'), sprintf('d%d_meanFiringRate', sessionNum));
numTrials = size(mfrt,1) - 1;
numCells = size(mfrt,2) - 1;

for iCell1 = 1:numCells
    for iCell2 = iCell1+1:numCells
        figure
        
        conTrials1 = 1:2:numTrials;
        conTrials2 = 2:2:numTrials;
        
        mfr1 = mfrt(2:end, iCell1+1);
        mfr2 = mfrt(2:end, iCell2+1);
        
        % context 1
        plot(mfr1(conTrials1), mfr2(conTrials1), 'ko', 'markerfacecolor', 'y')
        hold on
        plot(mfr1(conTrials2), mfr2(conTrials2), 'ks', 'markerfacecolor', 'b')
        xlabel(sprintf('Cell %d MFR (Hz)', iCell1))
        ylabel(sprintf('Cell %d MFR (Hz)', iCell2))
        grid on
        title(sprintf('Day %d', sessionNum))
    end
end
