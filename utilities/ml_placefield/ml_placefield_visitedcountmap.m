function [visitedCountMap] = ml_placefield_visitedcountmap(xi, yi, nbinsx, nbinsy)
    % Perform the counts by hand because I don't trust MATLAB
    numSamples = length(xi);

    visitedCountMap = zeros(nbinsy, nbinsx);
    for iVisited = 1:numSamples
        prevCount = visitedCountMap( yi(iVisited), xi(iVisited) );
        visitedCountMap( yi(iVisited), xi(iVisited) ) = prevCount + 1;
    end
end


