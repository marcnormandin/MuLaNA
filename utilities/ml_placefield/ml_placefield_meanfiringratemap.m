function [meanFiringRateMap] = ml_placefield_meanfiringratemap(spikeCountMap, dwellTimeMap)
    % Compute the mean firing rate map, lambda(x,y)
    %meanFiringRateMap = imgaussfilt(spikeCountMap,4)./ imgaussfilt(dwellTimeMap,8);
    meanFiringRateMap = spikeCountMap ./ dwellTimeMap;

    % There should be NANs for bins not visited
    meanFiringRateMap(isnan(meanFiringRateMap)) = 0;
    meanFiringRateMap(isinf(meanFiringRateMap)) = 0;
end

