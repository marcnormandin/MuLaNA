function [dwellTimeMap] = ml_placefield_dwelltimemap_v2(xi, yi, median_dt, nbinsx, nbinsy)
    numSamples = length(xi);
    
    % Perform the dwell time by hand because I don't trust MATLAB
    dwellTimeMap = zeros(nbinsy, nbinsx);
    for iVisited = 1:numSamples
        prevCount = dwellTimeMap( yi(iVisited), xi(iVisited) );
        dwellTimeMap( yi(iVisited), xi(iVisited) ) = prevCount + median_dt;
    end
end

