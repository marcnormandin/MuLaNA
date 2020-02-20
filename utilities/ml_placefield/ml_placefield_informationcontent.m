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