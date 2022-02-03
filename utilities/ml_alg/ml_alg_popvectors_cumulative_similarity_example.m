close all
clear all
clc

numCells = 10;
mapWidth = 10;
mapHeight = 15;
numTrials = 12;
numMaps = numCells * numTrials;

sdataMaps = nan(mapHeight, mapWidth, numMaps);
sdataCellIds = nan(numMaps, 1);
sdataTrialIds = nan(numMaps, 1);
sdataContextIds = nan(numMaps, 1);

k = 1;
for iTrial = 1:numTrials
    cid = mod(iTrial,2) + 1;
    for iCell = 1:numCells
        sdataCellIds(k) = iCell;
        sdataTrialIds(k) = iTrial;
        sdataContextIds(k) = cid;
        sdataMaps(:,:,k) = randn(mapHeight, mapWidth);
        k = k + 1;
    end
end

activityMapSet = [];
activityMapSet.maps = sdataMaps;
activityMapSet.cellIds = sdataCellIds;
activityMapSet.trialIds = sdataTrialIds;
activityMapSet.contextIds = sdataContextIds;
activityMapSet.numMaps = numMaps;

%%


[output] = ml_alg_best_aligned_average_context_maps_for_cell(1, sdataMaps, sdataCellIds, sdataTrialIds, sdataContextIds);
figure
subplot(1,2,1)
imagesc(output.context1.meanMap)
axis equal tight off
set(gca, 'ydir', 'reverse')
subplot(1,2,2)
imagesc(output.context2.meanMap)
axis equal tight off
set(gca, 'ydir', 'reverse')



%%
%[output] = ml_alg_popvectors_cumulative_similarity(sdataMaps, sdataCellIds, sdataTrialIds, sdataContextIds);

figure
plot(output.uzAcross, output.czAcross, 'r-')
hold on
plot(output.uzWithin, output.czWithin, 'b-')

