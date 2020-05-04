function [informationRate, informationPerSpike] = ml_placefield_informationcontent_v2(meanFiringRateMap, positionProbMap)
    % This must mathematically be true
    meanFiringRate = sum(meanFiringRateMap .* positionProbMap, 'all');
    
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
    
    % Numerical issues
    if isnan(informationRate) || isinf(informationRate)
        informationRate = 0;
    end
    
    % Compute the information per spike
    informationPerSpike = informationRate / meanFiringRate;
    
    % Numerical issues
    if isnan(informationPerSpike) || isinf(informationPerSpike)
        informationPerSpike = 0;
    end
end