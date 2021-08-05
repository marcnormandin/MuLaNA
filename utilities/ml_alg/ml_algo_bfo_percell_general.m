function [perCell, uniqueCellIds] = ml_algo_bfo_percell_general(placemaps, cellIds, contextIds, trialIds, rotationsDeg)
    uniqueCellIds = sort(unique(cellIds));
    uniqueContextIds = sort(unique(contextIds));
    uniqueTrialIds = sort(unique(trialIds));
    
    numTrials = length(uniqueTrialIds);

    numCells = length(uniqueCellIds);
    
    examplePlacemap = placemaps(:,:,1);
    placemapDim1 = size(examplePlacemap,1);
    placemapDim2 = size(examplePlacemap,2);
    placemapIsSquare = (placemapDim1 == placemapDim2);
    
    if any(ismember(rotationsDeg, [90, 270])) && ~placemapIsSquare
        error('Can not proceed because 90 or 270 degree rotations are requested, BUT the maps are not square. Maps are (%d, %d)', placemapDim1, placemapDim2);
    end

    perCell = [];
    for iCell = 1:numCells
        %iCell = randi(numCells, 1,1);
        cellId = uniqueCellIds(iCell);

        cellInds = find(cellIds == cellId);

        cellContextIds = contextIds(cellInds);
        cellTrialIds = trialIds(cellInds);
        cellMaps = placemaps(:,:, cellInds); % all maps, regardless of context

        numContexts = length(uniqueContextIds);

        % Now separate maps based on contexts.
        contextMaps = cell(numContexts,1);
        for iContext = 1:numContexts
            contextMaps{iContext} = cellMaps(:,:, find(cellContextIds == uniqueContextIds(iContext)));
        end

        % Any two contexts (all), c1-c1, c1-c2, c2-c2
        [perCell(iCell).v_any, perCell(iCell).vind_any, rotationsDeg] = ml_alg_bfo(rotationsDeg, cellMaps, cellMaps, false);

        % Same context, eg c1-c1, c2-c2
        for iContext = 1:numContexts
            [perCell(iCell).(sprintf('v_context%d', uniqueContextIds(iContext))), perCell(iCell).(sprintf('vind_context%d', uniqueContextIds(iContext))), rotationsDeg] = ml_alg_bfo(rotationsDeg, contextMaps{iContext}, contextMaps{iContext}, false);
        end

        % 
        if numContexts ~= 2
            error('This only works for two contexts')
        end

        [perCell(iCell).v_different, perCell(iCell).vind_different, rotationsDeg] = ml_alg_bfo(rotationsDeg, contextMaps{1}, contextMaps{2}, true);
    end % iCell
    
end % function
