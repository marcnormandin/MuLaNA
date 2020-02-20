function [spikeCountMap] = ml_placefield_spikecountmap(sxi, syi, nbinsx, nbinsy)
    % Perform the counts by hand because I don't trust MATLAB
    numSpikes = length(sxi);
    spikeCountMap = zeros(nbinsy, nbinsx);
    for iSpike = 1:numSpikes
        prevCount = spikeCountMap( syi(iSpike), sxi(iSpike) );
        spikeCountMap( syi(iSpike), sxi(iSpike) ) = prevCount + 1;
    end
end
