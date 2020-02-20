function [p, placeMap, activeMap, occupancyMap, notVisitedMap] = ml_nlx_placemaps_compute(visitedPos, activePos, activeVal, boundsi, boundsj, varargin)    
    p = inputParser;
    p.CaseSensitive = false;
        
    checkVisitedPos = @(x) size(x,2) == 2 && size(x,3) == 1 && isnumeric(x);
    addRequired(p,'visitedPos', checkVisitedPos);
    
    checkActivePos = @(x) size(x,2) == 2 && size(x,3) == 1 && isnumeric(x);
    addRequired(p,'activePos', checkActivePos);
    
    checkActiveVal = @(x) size(x,2) == 1 && isnumeric(x);
    addRequired(p,'activeVal', checkActiveVal);
    
    checkBounds = @(x) size(x,1) == 1 && size(x,2) == 2 && isnumeric(x);
    addRequired(p,  'boundsi', checkBounds); % [lower upper]
    addRequired(p,  'boundsj', checkBounds); % [lower upper]    
    addParameter(p, 'nbinsi', 20, @isscalar);
    addParameter(p, 'nbinsj', 20, @isscalar);
    
    addParameter(p, 'sigma', 2, @isnumeric);
    addParameter(p, 'smoothIndividualMaps', false, @islogical);
    addParameter(p, 'smoothFinalMap', true, @islogical);
    
    addParameter(p, 'excludeNotVisited', true, @islogical);
    addParameter(p, 'excludeNotVisitedValue', nan);
    
    addParameter(p, 'verbose', false, @islogical);
    
    expectedMapTypes = {'average', 'max'};
    defaultMapType = expectedMapTypes{1};
    addParameter(p, 'mapType', defaultMapType, @(x) any(validatestring(x,expectedMapTypes)));
    
    %addParameter(p, 'behavTrackCanFilename', 'behav_track_can.hdf5', @isstr);
    %addParameter(p, 'behavCamRoiFilename', 'behavcam_roi.mat', @isstr);
    %addParameter(p, 'flipHorizontal', false, @islogical);
    addParameter(p, 'applyConstraint', true, @islogical);
    %addParameter(p,'savePlots', true, @islogical);
    %addParameter(p,'closePlots', true, @islogical);
    
    parse(p, visitedPos, activePos, activeVal, boundsi, boundsj, varargin{:});

    if size(activePos,1) > size(visitedPos,1)
        error('The number of visited positions must be greater than or equal to the number of active positions.')
    end
    
    if size(activeVal,1) ~= size(activePos,1)
        error('Each value corresponding to activity should have one and only one position.');
    end
    
    % Form the grid
    nbinsi = p.Results.nbinsi;
    nbinsj = p.Results.nbinsj;
    iedges = linspace( p.Results.boundsi(1), p.Results.boundsi(2), nbinsi+1);
    jedges = linspace( p.Results.boundsj(1), p.Results.boundsj(2), nbinsj+1);
    
    % Occupancy map
    [occupancyMap, ~, ~, occupancyBinI, occupancyBinJ] = histcounts2(visitedPos(:,1), visitedPos(:,2), iedges, jedges);
    
    % Make a mask of where the occupancy is zero
    notVisitedMap = occupancyMap == 0;
    
    % Activity map
    xi = discretize(activePos(:,1), iedges);
    xj = discretize(activePos(:,2), jedges);
    activeMap = zeros(size(occupancyMap));
    if strcmp(p.Results.mapType, 'average') 
        for k = 1:size(activePos,1)
            if ~isnan(xi(k)) && ~isnan(xj(k))
                activeMap(xi(k), xj(k)) = activeMap(xi(k), xj(k)) + activeVal(k);
            end
        end
    elseif strcmp(p.Results.mapType, 'max')
        for k = 1:size(activePos,1)
            if ~isnan(xi(k)) && ~isnan(xj(k))
                activeMap(xi(k), xj(k)) = max([activeMap(xi(k), xj(k)), activeVal(k)]);
            end
        end
    else
        error('Invalid mapType (%s)', p.Results.mapType);
    end
    
    % Compute the placemap
    if p.Results.smoothIndividualMaps
        sigma = p.Results.sigma;
        
        activeMap = imgaussfilt(activeMap,sigma);  
        occupancyMap = imgaussfilt(occupancyMap,sigma);
               
        placeMap = activeMap ./ occupancyMap;
    else
        placeMap = activeMap ./ occupancyMap;
    end
    placeMap(isnan(placeMap)) = 0; % Set the NaN to zero (original version)
    placeMap(isinf(placeMap)) = 0; % This shouldn't be possible
    
    % Smooth the placemap
    if p.Results.smoothFinalMap
        sigma = p.Results.sigma;
        placeMap = imgaussfilt(placeMap, sigma);
    end

    % Apply the notvisitedmap
    if p.Results.excludeNotVisited
        activeMap(notVisitedMap) = p.Results.excludeNotVisitedValue;
        occupancyMap(notVisitedMap) = p.Results.excludeNotVisitedValue;
        placeMap(notVisitedMap) = p.Results.excludeNotVisitedValue;
    end
        
end % function
