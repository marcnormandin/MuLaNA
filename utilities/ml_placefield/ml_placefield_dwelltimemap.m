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

