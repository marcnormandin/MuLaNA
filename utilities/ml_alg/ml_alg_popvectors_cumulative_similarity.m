function [output] = ml_alg_popvectors_cumulative_similarity(sdataMaps, sdataCellIds, sdataTrialIds, sdataContextIds)
% sdataMaps should be a MxNxK matrix where P is the number of cells
% sdataCellIds should be a Kx1 array where each element is the cell id
% corresponding to the map
% sdataTrialIds should be a Kx1 array where each element is the trial id
% for the corresponding map
% sdataContextIds should be a Kx1 array where each elemen is the context id
% for the corresponding map

    numContexts = unique(sdataContextIds);
    if numContexts ~= 2
        error('There should be exactly two contexts.');
    end


    uniqueCellIds = unique(sdataCellIds);
    maps1 = []; % context one maps
    maps2 = []; % context two maps
    
    % Put the maps in closest comparable sequence possible
    for iCell = 1:length(uniqueCellIds)
        cellId = uniqueCellIds(iCell);
        cellInds = find(sdataCellIds == cellId);
        cmaps = sdataMaps(:,:,cellInds);
        tids = sdataTrialIds(cellInds);
        cids = sdataContextIds(cellInds);
                
        % Sort
        [s, ind] = sortrows([tids, cids]);
        
        % Now sort the data the same way
        cmaps = cmaps(:,:,ind);
        tids = s(:,1); % sorted trial ids
        cids = s(:,2); % sorted context ids

        
        firstContext = cids(1); % get the context with the first trial because we cant assume context 1 always is the first
        indsA = find( cids == firstContext );
        tidsA = tids( indsA );
        mapsA = cmaps(:,:, indsA);
        
        indsB = find( cids ~= firstContext );
        tidsB = tids( indsB ); % warning will only work with 2 contexts
        mapsB = cmaps(:,:, indsB);
        
        % see which trials of the first context have a match (next trial)
        % in the other context.
        use = ismember(tidsA+1,tidsB); 
        
        indsUseA = find(use == 1);
        
        indsUseB = nan(length(indsUseA),1); % each will be paired
        for k = 1:length(indsUseA)
            tb = tidsA( indsUseA(k) ) + 1;
            j = find(tidsB == tb);
            indsUseB(k) = j;
        end
        
        mapsA = mapsA(:,:, indsUseA);
        mapsB = mapsB(:,:, indsUseB);
        
        % Filter out maps where any pair is all zero
        bad = true(size(mapsA,3),1);
        for k = 1:size(mapsA,3)
            bad(k) = all(mapsA(:,:,k) == 0, 'all') | all(mapsB(:,:,k) == 0, 'all');
        end
        mapsA(:,:,bad) = [];
        mapsB(:,:,bad) = [];
        
        if firstContext == 1
            m1 = mapsA;
            m2 = mapsB;
        else
            m1 = mapsB;
            m2 = mapsA;
        end
        
        if isempty(maps1)
            maps1 = m1;
            maps2 = m2;
        else
            maps1 = cat(3, maps1, m1);
            maps2 = cat(3, maps2, m2);
        end
    end

    % I Tried normalizing this way, but resulting cumulatives were the
    % same.
    % for iMap = 1:size(maps1,3)
    %     m = maps1(:,:,iMap);
    %     
    %     s = nansum(m, 'all');
    %     m = m ./ s;
    %     m(~isfinite(m)) = 0;
    %     
    %     maps1(:,:,iMap) = m;
    % end
    % 
    % for iMap = 1:size(maps2,3)
    %     m = maps2(:,:,iMap);
    %     
    %     s = nansum(m, 'all');
    %     m = m ./ s;
    %     m(~isfinite(m)) = 0;
    %     
    %     maps2(:,:,iMap) = m;
    % end
    



    M = size(maps1,1);
    N = size(maps1,2);

    K1 = size(maps1,3);
    K2 = size(maps2,3);
    % K1 and K2 should be the same each context presented the same amount of
    % times

    % Each row is a population vector
    popVectors1 = reshape(maps1, M*N, K1);
    popVectors2 = reshape(maps2, M*N, K2);
    
    % Normalize each population vector
    for iMap = 1:size(popVectors1,1)
        m = popVectors1(iMap,:);
        m = m ./ sqrt(dot(m,m));
        popVectors1(iMap,:) = m;
    end
    for iMap = 1:size(popVectors2,1)
        m = popVectors2(iMap,:);
        m = m ./ sqrt(dot(m,m));
        popVectors2(iMap,:) = m;
    end
    
    

    % Make the vectors equal length if they are not CHOP CHOP off the last
    % columns
    K = min([K1, K2]);
    if K1 ~= K2
        K = min([K1, K2]);
        popVectors1(:,K+1:end) = [];
        popVectors2(:,K+1:end) = [];
    end

    numPopVectors = M * N;

    % Dot products of C1 with C1
    dots_1_1 = nan(numPopVectors*(numPopVectors-1)/2,1);
    k = 1;
    for iPop1 = 1:numPopVectors
        for iPop2 = iPop1+1:numPopVectors
            dots_1_1(k) = dot(popVectors1(iPop1,:), popVectors1(iPop2,:));
            k = k + 1;
        end
    end

    % Dot products of C2 with C2
    dots_2_2 = nan(numPopVectors*(numPopVectors-1)/2,1);
    k = 1;
    for iPop1 = 1:numPopVectors
        for iPop2 = iPop1+1:numPopVectors
            dots_2_2(k) = dot(popVectors2(iPop1,:), popVectors2(iPop2,:));
            k = k + 1;
        end
    end


    % Dot products of C1 with C2
    dots_1_2 = nan(numPopVectors*numPopVectors,1);
    k = 1;
    for iPop1 = 1:numPopVectors
        for iPop2 = 1:numPopVectors
            dots_1_2(k) = dot(popVectors1(iPop1,:), popVectors2(iPop2,:));
            k = k + 1;
        end
    end

    [uzC1,czC1] = ml_alg_cumdist(dots_1_1);
    [uzC2,czC2] = ml_alg_cumdist(dots_2_2);
    [uzAcross,czAcross] = ml_alg_cumdist(dots_1_2);
    [uzWithin,czWithin] = ml_alg_cumdist(cat(1, dots_1_1, dots_2_2));
    
    % store for output
    output.numPopVectors = numPopVectors;
    output.K1 = K1;
    output.K2 = K2;
    output.K = K;
    output.uzC1 = uzC1;
    output.czC1 = czC1;
    output.uzC2 = uzC2;
    output.czC2 = czC2;
    output.uzAcross = uzAcross;
    output.czAcross = czAcross;
    output.uzWithin = uzWithin;
    output.czWithin = czWithin;
end % function
    