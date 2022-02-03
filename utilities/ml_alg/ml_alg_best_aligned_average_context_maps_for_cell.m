function [output] = ml_alg_best_aligned_average_context_maps_for_cell(cellId, sdataMaps, sdataCellIds, sdataTrialIds, sdataContextIds, comparisonMethod)
% sdataMaps should be a MxNxK matrix where P is the number of cells
% sdataCellIds should be a Kx1 array where each element is the cell id
% corresponding to the map
% sdataTrialIds should be a Kx1 array where each element is the trial id
% for the corresponding map
% sdataContextIds should be a Kx1 array where each elemen is the context id
% for the corresponding map
%
% cellId must be an id in the sdataCellIds array. It is not an index.

    %uniqueCellIds = unique(sdataCellIds);
    
    cellInds = find(sdataCellIds == cellId);
    if isempty(cellInds)
        output = [];
        warning('Cell with ID %d not found.\n', cellId);
        return
    end
    
    cellMapsMean = sdataMaps(:,:, cellInds);

    trialIds = sdataTrialIds(cellInds);
    contextIds = sdataContextIds(cellInds);

    numMaps = size(cellMapsMean,3);

    for iMap = 1:numMaps
       mm = cellMapsMean(:,:,iMap);
       mm(~isfinite(mm)) = 0;

       cellMapsMean(:,:,iMap) = mm;
    end

    cellMaps1 = cellMapsMean(:,:, contextIds == 1);
    cellMaps2 = cellMapsMean(:,:, contextIds == 2);
    
    [finalMean1, bestCombination1] = best_flip_combinations(cellMaps1, comparisonMethod);
    [finalMean2, bestCombination2] = best_flip_combinations(cellMaps2, comparisonMethod);

    c1 = corr(finalMean1(:), finalMean2(:));
    c2 = corr(finalMean1(:), rot90(finalMean2(:), 2));
    if c2 > c1
        finalMean2 = rot90( finalMean2, 2 );
        bestCombination2 = xor(bestCombination2, ones(1,length(bestCombination2)));
    end

    flippedMaps1 = cellMaps1;
    ind1 = find(bestCombination1 == 1);
    for k = 1:length(ind1)
        flippedMaps1(:,:,ind1(k)) = rot90( flippedMaps1(:,:,ind1(k)), 2 );
    end
    flippedMaps2 = cellMaps2;
    ind2 = find(bestCombination2 == 1);
    for k = 1:length(ind2)
        flippedMaps2(:,:,ind2(k)) = rot90( flippedMaps2(:,:,ind2(k)), 2 );
    end
    
    % store the output
    output.context1.meanMap = finalMean1;
    output.context1.flipSequence = bestCombination1;
    output.context1.flippedMaps = flippedMaps1;
    output.context1.trialIds = trialIds( contextIds == 1 );
    
    output.context2.meanMap = finalMean2;
    output.context2.flipSequence = bestCombination2;
    output.context2.flippedMaps = flippedMaps2;
    output.context2.trialIds = trialIds( contextIds == 2 );

end % function


function [bestMap, bestCombination] = best_flip_combinations(maps, comparisonMethod)
    comparisonMethod = lower(comparisonMethod);

    if strcmpi(comparisonMethod, 'mutualInformation')
        [bestMap, bestCombination] = best_flip_combinations_mutualinformation(maps);
    elseif strcmpi(comparisonMethod, 'difference')
        [bestMap, bestCombination] = best_flip_combinations_difference(maps);
    elseif strcmpi(comparisonMethod, 'standardDeviation')
        [bestMap, bestCombination] = best_flip_combinations_standarddeviation(maps);
    elseif strcmpi(comparisonMethod, 'correlation')
        [bestMap, bestCombination] = best_flip_combinations_correlation(maps);
    else
        error('Invalid comparison method.');
    end
end % function
        

function [bestMap, bestCombination] = best_flip_combinations_mutualinformation(maps)
    
    numTrials = size(maps,3);

    flipCombinations = flip_combinations(numTrials);
    numCombinations = size(flipCombinations,1);

    flipMetric = zeros(numCombinations,1);
    flippedMap = zeros(size(maps,1), size(maps,2), numCombinations);

    maps = maps ./ sum(maps, [1,2]); % shouldn't affect the mutual information
    
    for iComb = 1:numCombinations
       comb = flipCombinations(iComb,:);
       mc = maps;
       ind = find(comb == 1);
       for k = 1:length(ind)
           mc(:,:,ind(k)) = rot90(mc(:,:,ind(k)), 2);
       end
       
       
           % Use mutual information as the metric for comparing maps.

           % Prep all of the images
           NUM_BINS = 32; % This is how many bins the map values will be binned into. It is not the map dimensions.
           mcPrep = zeros(size(mc));
           for iTrial = 1:numTrials
               mcPrep(:,:,iTrial) = ml_alg_entropy_prep_image(mc(:,:,iTrial), NUM_BINS);
           end
       
           k = 1;
           mutualInformation = zeros( numTrials*(numTrials-1)/2, 1);
           for iTrialA = 1:numTrials
               for iTrialB = iTrialA+1:numTrials
                   try
                    mutualInformation(k) = ml_alg_mutual_information_images( mcPrep(:,:,iTrialA), mcPrep(:,:,iTrialB) );
                    k = k + 1;
                   catch e

                   end
               end
           end

           flipMetric(iComb) = nanmax(mutualInformation);
           flippedMap(:,:,iComb) = mean(mc, 3, 'omitnan');
    end % iComb

    [~, j] = max(flipMetric); % best is maximum mean mutual information
    bestMap = flippedMap(:,:,j);
    bestCombination = flipCombinations(j,:);
end % function

function [bestMap, bestCombination] = best_flip_combinations_difference(maps)
    
    numTrials = size(maps,3);

    flipCombinations = flip_combinations(numTrials);
    numCombinations = size(flipCombinations,1);

    flipMetric = zeros(numCombinations,1);
    flippedMap = zeros(size(maps,1), size(maps,2), numCombinations);

    maps = maps ./ sum(maps, [1,2]);
    
    for iComb = 1:numCombinations
       comb = flipCombinations(iComb,:);
       mc = maps;
       ind = find(comb == 1);
       for k = 1:length(ind)
           mc(:,:,ind(k)) = rot90(mc(:,:,ind(k)), 2);
       end
       
      
       
       k = 1;
       comparisons = zeros( numTrials*(numTrials-1)/2, 1);
       for iTrialA = 1:numTrials
           for iTrialB = iTrialA+1:numTrials
               try
                comparisons(k) = sum(abs( mc(:,:,iTrialA) - mc(:,:,iTrialB) ), 'all');
                k = k + 1;
               catch e

               end
           end
       end

       flipMetric(iComb) = nanmean(comparisons);
       flippedMap(:,:,iComb) = mean(mc, 3, 'omitnan');
    end

    [~, j] = min(flipMetric);
    bestMap = flippedMap(:,:,j);
    bestCombination = flipCombinations(j,:);
end % function

function [bestMap, bestCombination] = best_flip_combinations_standarddeviation(maps)
    
    numTrials = size(maps,3);

    flipCombinations = flip_combinations(numTrials);
    numCombinations = size(flipCombinations,1);

    flipMetric = zeros(numCombinations,1);
    flippedMap = zeros(size(maps,1), size(maps,2), numCombinations);

    maps = maps ./ sum(maps, [1,2]);
    
    for iComb = 1:numCombinations
       comb = flipCombinations(iComb,:);
       mc = maps;
       ind = find(comb == 1);
       for k = 1:length(ind)
           mc(:,:,ind(k)) = rot90(mc(:,:,ind(k)), 2);
       end

        flipMetric(iComb) = sum(std(mc, 0, 3, 'omitnan'), 'all', 'omitnan');
        flippedMap(:,:,iComb) = mean(mc, 3, 'omitnan');
    end % iComb

    [~, j] = min(flipMetric);
    bestMap = flippedMap(:,:,j);
    bestCombination = flipCombinations(j,:);
end % function

function [bestMap, bestCombination] = best_flip_combinations_correlation(maps)
    
    numTrials = size(maps,3);

    flipCombinations = flip_combinations(numTrials);
    numCombinations = size(flipCombinations,1);

    flipMetric = zeros(numCombinations,1);
    flippedMap = zeros(size(maps,1), size(maps,2), numCombinations);

    maps = maps ./ sum(maps, [1,2]);
    
    for iComb = 1:numCombinations
       comb = flipCombinations(iComb,:);
       mc = maps;
       ind = find(comb == 1);
       for k = 1:length(ind)
           mc(:,:,ind(k)) = rot90(mc(:,:,ind(k)), 2);
       end
       
       

        k = 1;
        comparison = zeros( numTrials*(numTrials-1)/2, 1);
        for iTrialA = 1:numTrials
           for iTrialB = iTrialA+1:numTrials
               try
                mapA = mc(:,:,iTrialA);
                mapB = mc(:,:,iTrialB);
                comparison(k) = corr(mapA(:), mapB(:));
                k = k + 1;
               catch e

               end
           end
        end

        flipMetric(iComb) = nanmean(comparison);
        flippedMap(:,:,iComb) = mean(mc, 3, 'omitnan');
       
    end

    [~, j] = max(flipMetric);
    bestMap = flippedMap(:,:,j);
    bestCombination = flipCombinations(j,:);
end % function



function [flipCombinations] = flip_combinations(numTrials)
    % Returns a matrix of unique combinations of 0s and 1s. Each row
    % is one combination.
    flipCombinations = zeros(1,numTrials);

    for i = 1:numTrials %6
        s = zeros(numTrials,1);
        s(1:i) = 1;
        p = unique(perms(s), 'rows');

        flipCombinations = cat(1, flipCombinations, p);
    end

    flipCombinations = unique(flipCombinations, 'rows'); % precaution
end % function