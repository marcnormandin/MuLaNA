function [x_bounded, y_bounded, xedges, yedges, xi, yi, sxi, syi, ...
    spikeCountMap, visitedCountMap, dwellTimeMap, ...
    positionProbMap, meanFiringRateMap, ...
    meanFiringRate, peakFiringRate, ...
    informationRate, informationPerSpike, ...
    dwellTimeMapSmoothed, meanFiringRateMapSmoothed, ...
    meanFiringRateMapPlot, dwellTimeMapPlot, ...
    meanFiringRateMapSmoothedPlot ] = ml_spm_compute_all(x, y, ts_mus, si, boundsx, boundsy, nbinsx, nbinsy, smoothingKernel)
    ts_s = (ts_mus - ts_mus(1)) / 10^6;

    [x_bounded, y_bounded, xi, yi, xedges, yedges] = ml_core_compute_binned_positions(x, y, boundsx, boundsy, nbinsx, nbinsy);

    % Recompute the spike location since we could have potentially changed
    % the subjects location when the spike occurred. 
    sxi = xi(si);
    syi = yi(si);

    spikeCountMap = ml_placefield_spikecountmap(sxi, syi, nbinsx, nbinsy);
    visitedCountMap = ml_placefield_visitedcountmap(xi, yi, nbinsx, nbinsy);
    dwellTimeMap = ml_placefield_dwelltimemap(xi, yi, ts_s, nbinsx, nbinsy);
    
    positionProbMap = ml_placefield_positionprobmap(dwellTimeMap);
    meanFiringRateMap = ml_placefield_meanfiringratemap(spikeCountMap, dwellTimeMap); %imgaussfilt(spikeCountMap, smoothFactor); %ml_placefield_meanfiringratemap(spikeCountMap, dwellTimeMap, smoothFactor);
    
    % Calculate some values from the maps
    [meanFiringRate, peakFiringRate] = ml_placefield_firingrate(meanFiringRateMap, positionProbMap);
    [informationRate, informationPerSpike] = ml_placefield_informationcontent(meanFiringRate, meanFiringRateMap, positionProbMap);

    %kernel = fspecial('gaussian', kernelGaussianSize_bins, kernelGaussianSigma_cm);
    %kernel = kernel ./ max(max(kernel));
    


    dwellTimeMapSmoothed = imfilter(dwellTimeMap, kernel);
    
end