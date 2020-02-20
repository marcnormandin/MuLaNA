close all
clear all
clc

tFilenames = dir('TT*.t');
spikeTimes_mus = cell(length(tFilenames),1);
for iT = 1:length(tFilenames)
    tFilename = tFilenames(iT).name;
    fprintf('Loading %s\n', tFilename);
    spikeTimes_mclust = ml_nlx_mclust_load_spikes_64bit(tFilename);
    spikeTimes_mus{iT} = spikeTimes_mclust{1}.T(:) .* 10^6;
end
numCells = length(spikeTimes_mus);

% Set the time origin to be zero by subtracting the minimum spike time

figure
hold all
%colours = {'r','g','b','m','k'};
for iCell = 1:numCells
    spikePos = spikeTimes_mus{iCell};
    for spikeCount = 1:length(spikePos)
        plot([spikePos(spikeCount) spikePos(spikeCount)], [iCell-0.4, iCell+0.4], 'k') %colours{iCell})
    end
end
yticks(1:numCells);
yticklabels({tFilenames.name})
set(gca,'TickLabelInterpreter','none')
ylim([0, numCells+1]);
ylabel('Cell')
xlabel('Time');
grid on
grid minor
