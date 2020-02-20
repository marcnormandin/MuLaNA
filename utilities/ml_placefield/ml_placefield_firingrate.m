function [meanFiringRate, peakFiringRate] = ml_placefield_firingrate(meanFiringRateMap, positionProbMap)
    % Compute the mean firing rate across all of the locations
    meanFiringRate = sum( meanFiringRateMap .* positionProbMap, 'all' );
    peakFiringRate = max(meanFiringRateMap(:));
end


