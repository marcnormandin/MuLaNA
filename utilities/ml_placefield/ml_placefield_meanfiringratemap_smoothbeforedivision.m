function [meanFiringRateMap] = ml_placefield_meanfiringratemap_smoothbeforedivision(spikeCountMap, dwellTimeMap, kernel)
    % Compute the mean firing rate map, lambda(x,y)
    %meanFiringRateMap = imgaussfilt(spikeCountMap,4)./ imgaussfilt(dwellTimeMap,8);

    meanFiringRateMap = imfilter(spikeCountMap, kernel) ./ imfilter(dwellTimeMap, kernel);

    % There should be NANs for bins not visited
    meanFiringRateMap(isnan(meanFiringRateMap)) = 0;
    meanFiringRateMap(isinf(meanFiringRateMap)) = 0;
end

