function [x_bounded, y_bounded, xedges, yedges, xi, yi, sxi, syi, ...
    spikeCountMap, visitedCountMap, dwellTimeMap, ...
    positionProbMap, meanFiringRateMap, ...
    dwellTimeMapSmoothed, spikeCountMapSmoothed, meanFiringRateMapSmoothed, ...
    meanFiringRateMapPlot, dwellTimeMapPlot, ...
    meanFiringRateMapSmoothedPlot ] = ml_cai_placefield_compute_all(x, y, ts_ms, si, boundsx, boundsy, nbinsx, nbinsy, gaussianSigmaBeforeDivision, gaussianSigmaAfterDivision)
    ts_s = (ts_ms - ts_ms(1)) / 10^3;

    [x_bounded, y_bounded, xi, yi, xedges, yedges] = ml_core_compute_binned_positions(x, y, boundsx, boundsy, nbinsx, nbinsy);

    % Recompute the spike location since we could have potentially changed
    % the subjects location when the spike occurred. 
    sxi = xi(si);
    syi = yi(si);

    spikeCountMap = ml_placefield_spikecountmap(sxi, syi, nbinsx, nbinsy);
    visitedCountMap = ml_placefield_visitedcountmap(xi, yi, nbinsx, nbinsy);
    dwellTimeMap = ml_placefield_dwelltimemap(xi, yi, ts_s, nbinsx, nbinsy);
    
    positionProbMap = ml_placefield_positionprobmap(dwellTimeMap);
    
    meanFiringRateMap = ml_placefield_meanfiringratemap(spikeCountMap, dwellTimeMap, gaussianSigmaBeforeDivision);
    
    % Smooth it after resizing
    if gaussianSigmaBeforeDivision ~= 0
        dwellTimeMapSmoothed = imgaussfilt(dwellTimeMap, gaussianSigmaBeforeDivision);
    else
        dwellTimeMapSmoothed = dwellTimeMap;
    end
    
    if gaussianSigmaBeforeDivision ~= 0
        spikeCountMapSmoothed = imgaussfilt(spikeCountMap, gaussianSigmaBeforeDivision);
    else
        spikeCountMapSmoothed = spikeCountMap;
    end
    
    if gaussianSigmaAfterDivision ~= 0
        meanFiringRateMapSmoothed = imgaussfilt(meanFiringRateMap, gaussianSigmaAfterDivision);
    else
        meanFiringRateMapSmoothed = meanFiringRateMap;
    end

    % Knock-out the unvisited bins for the plots
    meanFiringRateMapPlot = meanFiringRateMap;
    meanFiringRateMapPlot(visitedCountMap == 0) = nan;

    dwellTimeMapPlot = dwellTimeMapSmoothed;
    dwellTimeMapPlot(visitedCountMap == 0) = nan;

    meanFiringRateMapSmoothedPlot = meanFiringRateMapSmoothed;
    meanFiringRateMapSmoothedPlot(visitedCountMap == 0) = nan;
end