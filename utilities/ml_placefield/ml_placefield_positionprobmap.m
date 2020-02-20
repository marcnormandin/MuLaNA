function [positionProbMap] = ml_placefield_positionprobmap(dwellTimeMap)
    % Location probability, p(x,y)
    positionProbMap = dwellTimeMap / sum(dwellTimeMap, 'all');
end

