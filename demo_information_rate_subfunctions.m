function [meanFiringRate, peakFiringRate, informationRate, informationPerSpike] = demo_information_rate_subfunctions(iSingleunit, iTrial)
%close all
%clear all
%clc

% These ones work great!
%iSingleunit = 4;
%iTrial = 9;

% Noise
%iSingleunit = 2;
%iTrial = 8;

[canon, spikes] = load_data(iSingleunit, iTrial);

% figure
% plot(canon.pos.x, canon.pos.y, 'b.')
% hold on
% plot(spikes.pos.x, spikes.pos.y, 'ro', 'markerfacecolor', 'r')
% set(gca, 'ydir', 'reverse')
% grid on
% axis equal

x = canon.pos.x;
y = canon.pos.y;
si = spikes.indices;
ts_ms = canon.timeStamps(:); 
ts_s = (ts_ms - ts_ms(1)) / 10^6;
    
% Form the grid
boundsx = [0, 20];
boundsy = [0, 30];
nbinsx = 10;
nbinsy = 15;

[x, y, xi, yi, xedges, yedges] = ml_core_compute_binned_positions(x, y, boundsx, boundsy, nbinsx, nbinsy);

% Recompute the spike location since we could have potentially changed
% the subjects location when the spike occurred. 
sxi = xi(si);
syi = yi(si);

[spikeCountMap] = ml_placefield_spikecountmap(sxi, syi, nbinsx, nbinsy);
[visitedCountMap] = ml_placefield_visitedcountmap(xi, yi, nbinsx, nbinsy);
[dwellTimeMap] = ml_placefield_dwelltimemap(xi, yi, ts_s, nbinsx, nbinsy);
[meanFiringRateMap] = ml_placefield_meanfiringratemap(spikeCountMap, dwellTimeMap);
[positionProbMap] = ml_placefield_positionprobmap(dwellTimeMap);
[meanFiringRate, peakFiringRate] = ml_placefield_firingrate(meanFiringRateMap, positionProbMap);
[informationRate, informationPerSpike] = ml_placefield_informationcontent(meanFiringRate, meanFiringRateMap, positionProbMap);

% figure
% plot(xi, yi, 'b.')
% hold on
% set(gca, 'ydir', 'reverse')
% grid on
% axis equal
% plot(sxi, syi, 'ro', 'markerfacecolor', 'r', 'markersize', 8)
% 
% figure
% imagesc(spikeCountMap)
% colorbar
% colormap jet
% axis image
% title('Spike count map')
% 
% figure
% imagesc(visitedCountMap)
% colorbar
% colormap jet
% axis image
% title('Visited count map')
% 
% figure
% imagesc(dwellTimeMap)
% colorbar
% colormap jet
% axis image
% title('Dwell time map')

% figure
% subplot(1,2,1)
% imagesc(meanFiringRateMap)
% colorbar
% colormap jet
% axis image
% title('Firing rate map (no smooth)')
% 
% subplot(1,2,2)
% imagesc(imgaussfilt(imresize(meanFiringRateMap,2),2))
% colorbar
% colormap jet
% axis image
% title('Firing rate map (smoothed)')

% figure
% imagesc(positionProbMap)
% colorbar
% colormap jet
% axis image
% title('Position probability map')

fprintf('Mean firing rate (lambda) = %f Hz\n', meanFiringRate);
fprintf('Peak firing rate = %f Hz\n', peakFiringRate);
fprintf('Information rate = %f bits/s\n', informationRate);
fprintf('Information per spike = %f bits\n', informationPerSpike);
end

function [canon, spikes] = load_data(iSingleunit, iTrial)
    data = load(sprintf('singleunit_%d.mat', iSingleunit));
    singleunit = data.singleunit;
    spikes = singleunit.trialSpikes(iTrial);

    data = load(sprintf('trial_%d_canon.mat', iTrial));
    canon = data.canon;
end


function [x, y, xi, yi, xedges, yedges] = ml_core_compute_binned_positions(x, y, boundsx, boundsy, nbinsx, nbinsy)
    xedges = linspace( boundsx(1), boundsx(2), nbinsx+1);
    yedges = linspace( boundsy(1), boundsy(2), nbinsy+1);
    
    % Force (should be optional) each outside point to the closest interior
    % point so that they are all used
    x(x < boundsx(1)) = boundsx(1);
    x(x > boundsx(2)) = boundsx(2);
    y(y < boundsy(1)) = boundsy(1);
    y(y > boundsy(2)) = boundsy(2);

    xi = discretize(x, xedges);
    yi = discretize(y, yedges);

    xi_outside = find(isnan(xi));
    yi_outside = find(isnan(yi));
    i_outside = union(xi_outside, yi_outside);

    % The math fails if any points are outside, so if there are, remove them
    if ~isempty(i_outside)
        error('Algorithm can not work with points outside the bounds')
    end
end


function [spikeCountMap] = ml_placefield_spikecountmap(sxi, syi, nbinsx, nbinsy)
    % Perform the counts by hand because I don't trust MATLAB
    numSpikes = length(sxi);
    spikeCountMap = zeros(nbinsy, nbinsx);
    for iSpike = 1:numSpikes
        prevCount = spikeCountMap( syi(iSpike), sxi(iSpike) );
        spikeCountMap( syi(iSpike), sxi(iSpike) ) = prevCount + 1;
    end
end

function [visitedCountMap] = ml_placefield_visitedcountmap(xi, yi, nbinsx, nbinsy)
    % Perform the counts by hand because I don't trust MATLAB
    numSamples = length(xi);

    visitedCountMap = zeros(nbinsy, nbinsx);
    for iVisited = 1:numSamples
        prevCount = visitedCountMap( yi(iVisited), xi(iVisited) );
        visitedCountMap( yi(iVisited), xi(iVisited) ) = prevCount + 1;
    end
end


function [dwellTimeMap] = ml_placefield_dwelltimemap(xi, yi, ts_s, nbinsx, nbinsy)
    numSamples = length(xi);
    
    % Check the uniformity of the timestamps
    dts_s = diff([0; ts_s(:)]);

    % Perform the dwell time by hand because I don't trust MATLAB
    dwellTimeMap = zeros(nbinsy, nbinsx);
    for iVisited = 1:numSamples
        prevCount = dwellTimeMap( yi(iVisited), xi(iVisited) );
        dwellTimeMap( yi(iVisited), xi(iVisited) ) = prevCount + dts_s(iVisited);
    end
end

function [meanFiringRateMap] = ml_placefield_meanfiringratemap(spikeCountMap, dwellTimeMap)
    % Compute the mean firing rate map, lambda(x,y)
    meanFiringRateMap = spikeCountMap ./ dwellTimeMap;
    % There should be NANs for bins not visited
    meanFiringRateMap(isnan(meanFiringRateMap)) = 0;
end

function [positionProbMap] = ml_placefield_positionprobmap(dwellTimeMap)
    % Location probability, p(x,y)
    positionProbMap = dwellTimeMap / sum(dwellTimeMap, 'all');
end

function [meanFiringRate, peakFiringRate] = ml_placefield_firingrate(meanFiringRateMap, positionProbMap)
    % Compute the mean firing rate across all of the locations
    meanFiringRate = sum( meanFiringRateMap .* positionProbMap, 'all' );
    peakFiringRate = max(meanFiringRateMap(:));
end


function [informationRate, informationPerSpike] = ml_placefield_informationcontent(meanFiringRate, meanFiringRateMap, positionProbMap)
    % Compute the information rate (bits per second)
    % Find the non-zero entries of the position probability
    [nzi, nzj] = find( positionProbMap > 0 );
    informationRate = 0;
    for i = 1:length(nzi)
        mfrij = meanFiringRateMap(nzi(i), nzj(i));
        if mfrij ~= 0
            integrand = mfrij * log2( mfrij / meanFiringRate ) * positionProbMap(nzi(i), nzj(i));
        else
            integrand = 0;
        end
        informationRate = informationRate + integrand;
    end
    
    % Compute the information per spike
    informationPerSpike = informationRate / meanFiringRate;
end

