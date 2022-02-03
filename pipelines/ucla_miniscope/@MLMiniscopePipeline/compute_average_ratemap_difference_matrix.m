function compute_average_ratemap_difference_matrix(obj, session)
    animalName = obj.Experiment.getAnimalName();
    sessionName = session.getName();
    sessionAnalysisFolder = session.getAnalysisDirectory();
    
    % sessionName = session.getName();
    % sessionAnalysisFolder = fullfile('R:\chengs_task_2c\data\minimice\feature_rich', animalName, 'analysis_sat', sessionName);

    % Placemap database
    fnpm = fullfile(sessionAnalysisFolder, sprintf('%s_placemaps.mat', sessionName));
    pmDatabase = load(fnpm);
    
    %maps = pmDatabase.maps;
    mapNameToUse = obj.Config.calcium_average_ratemaps.map_name_to_use;
    maps = pmDatabase.(mapNameToUse);
    
    numMaps = size(maps,3); % number of maps in total across all cells and all trials

    trialIds = pmDatabase.trialIds;
    numTrials = pmDatabase.numTrials;
    traceMaximums = pmDatabase.traceMaximums;
    cellIds = pmDatabase.cellIds;
    contextIds = pmDatabase.contextIds;

    % Occupancy maps (one per trial)
    probMapTrials = nan(size(maps,1), size(maps,2), numTrials);

    % We have to load the mcmappy to get the probability map since we dont have
    % them collected in a separate database
    for iTrial = 1:numTrials
        trialFolder = fullfile(sessionAnalysisFolder, sprintf('trial_%d', iTrial));
        pmFilename = fullfile(trialFolder, 'mcmappy.mat');
        pmData = load(pmFilename);

        if contains(lower(mapNameToUse), "smoothed" )
            probMapTrials(:,:,iTrial) = pmData.probMapSmoothed;
        else
            probMapTrials(:,:,iTrial) = pmData.probMap;
        end
        
    end

    % SCALE each cell to it's maximum rate across all of the trials
    uniqueCellIds = unique(cellIds);
    numUniqueCells = length(uniqueCellIds);
%     for iCell = 1:numUniqueCells
%         cid = uniqueCellIds(iCell);
%         cellInds = find(pmDatabase.cellIds == cid);
%         maxValue = max(maps(:,:,cellInds), [], 'all');
%         for k = 1:length(cellInds)
%            j = cellInds(k);
%            maps(:,:,j) = maps(:,:,j) ./ maxValue;
%         end
%     end

    % We have the trace maximums for EACH trial and EACH cell, so we need
    % to find the trace maximum for EACH cell ACROSS ALL TRIALS
    sessionTraceMaximums = zeros(size(traceMaximums));
    for iCell = 1:numUniqueCells
       cellId = uniqueCellIds(iCell); % get one cell
       
       cellInds = find(cellIds == cellId);
       cellTraceMaximums = traceMaximums(cellInds);
       sessionTraceMaximums(cellInds) = max(cellTraceMaximums, [], 'omitnan');
    end

    % For each event map that we have, compute and store the average rate
    avg = nan(numMaps, 1);
    for k = 1:numMaps
        tid = trialIds(k);
        probMap = probMapTrials(:,:,tid);
        eventMap = maps(:,:,k);

        normalizationFactor = 1;
        %normalizationFactor = 1 ./ sessionTraceMaximums(k);
        %normalizationFactor = 1 ./ traceMaximums(k);
        avg(k) = nansum( eventMap .* probMap .* normalizationFactor, 'all' );
    end

    avgF = avg;

    % DEBUG
%     cellPreferredContext = zeros(numMaps,1);
%     cellPreferredRate = zeros(numMaps,1);
%     for iCell = 1:numUniqueCells
%         cellId = uniqueCellIds(iCell);
%         cellIdIndices = find(cellIds == cellId);
%         cellPreferredContext(cellIdIndices) = randi(2);
%         cellPreferredRate(cellIdIndices) = 200 + 100*randn(length(cellIdIndices),1);
%     end
%     for k1 = 1:numMaps
%         trial1 = trialIds(k1); % Get the actual trial id
%         %cellId1 = cellIds(k1); % get the actual cell id
%         contextId1 = contextIds(k1);
%         pc = cellPreferredContext(k1);
%         
%         if cellPreferredRate(k1) < 0
%             cellPreferredRate(k1) = 0;
%         end
%         
%         avgF(k1) = cellPreferredRate(k1) .* sqrt(0.1+trial1/numTrials);
%     end
    
    % Now we will filter the data
    % Load the inclusion data
    APPLY_FILTER = obj.Config.calcium_average_ratemaps.apply_filter_information_content | ...
        obj.Config.calcium_average_ratemaps.apply_filter_celllike_spatial_footprint;
    if APPLY_FILTER
        inclusionFilename = fullfile(sessionAnalysisFolder, sprintf('%s_placemaps_inclusion.mat', sessionName));
        if isfile(inclusionFilename)
            inclusionData = load(inclusionFilename);
            inclusionData = inclusionData.inclusionData;
            
            inclusion = true(size(avgF));

            if obj.Config.calcium_average_ratemaps.apply_filter_information_content
                inclusion = inclusion & inclusionData.passedInformationContentFilter;
            end
            
            if obj.Config.calcium_average_ratemaps.apply_filter_celllike_spatial_footprint
                inclusion = inclusion & inclusionData.passedCelllikeSpatialFootprintFilter;
            end
            
            doNotInclude = find( inclusion == 0 );

            % Now apply the filter by setting values we wont use to NAN. Later on we
            % will use nanmean to average without nans.
            avgF(doNotInclude) = nan;
        else
            warning('Filtering of cells enabled for fluorescence, but %s is not found so filtering will not be applied.', inclusionFilename);
        end
    end

    % Sort the rate matrix rows and cols by context, so that we can see
    % patterns based on context more easily.
    % Get the unique combinations of (trial id, context id)
    urows = unique([trialIds, contextIds], 'rows');
    [surows, ind] = sortrows(urows, 2);
    rateMatrixContextIds = surows(:,2);
    rateMatrixTrialIds = surows(:,1);% trial ids ordered by context
    trialIdToIndex = zeros(1, length(ind)); % map from a trialid to its index in the matrix
    uTrialIds = unique(trialIds);
    % Now make a map from trialId to its index into the matrix
    for k = 1:length(ind)
       j = find(rateMatrixTrialIds == uTrialIds(k));
       trialIdToIndex(k) = j;
    end
    
    % Make labels for the rows and columns
    rateMatrixLabels = cell(length(rateMatrixContextIds),1);
    for i = 1:length(surows)
        rateMatrixLabels{i} = sprintf('C%d-T%0.2d', rateMatrixContextIds(i), rateMatrixTrialIds(i));
    end

    % Now put the values that we computed into respective 3D matrix location
%     trialIds = pmDatabase.trialIds;
%     cellIds = pmDatabase.cellIds;
%     numCells = length(unique(cellIds)); 
    rateMatrices = nan(numTrials, numTrials, numUniqueCells); % 3rd dimension is the cell id
    for k1 = 1:numMaps
      for k2 = 1:numMaps
          trial1 = trialIds(k1); % Get the actual trial id
          trial2 = trialIds(k2); % Get the actual trial id
          cellId1 = cellIds(k1); % get the actual cell id
          cellId2 = cellIds(k2); % get the actual cell id

          % If the maps are not from the same cell, then skip it
          if cellId1 ~= cellId2
              continue;
          end
          
          if trial1 == trial2 % We dont care about trial with itself
              continue;
          end
          
          cellId = cellId1; % or 2 because they are equal

          avgF1 = avgF(k1);
          avgF2 = avgF(k2);

          rateDiff = abs( avgF1 - avgF2 );

          rmrow = trialIdToIndex(trial1);
          rmcol = trialIdToIndex(trial2);

          rateMatrices(rmrow, rmcol, cellId) = rateDiff;

          %fprintf('Cell %d: T%d with T%d has rate difference %0.2f. Placed into rate matrix location (%d, %d)\n', cid, trial1, trial2, rateDiff, rmrow, rmcol);
      end
    end
    
    % Weight each cell equally?
    for iCell = 1:numUniqueCells
       s = nansum( rateMatrices(:,:,iCell), 'all' );
       rateMatrices(:,:,iCell) = rateMatrices(:,:,iCell) ./ s;
    end
    
    % Average over the 3D matrix to get the 2D matrix
    meanRateMatrix = nanmean(rateMatrices, 3);
    meanRateMatrix(eye(size(meanRateMatrix))==1) = nan; % set diagonal to nan

    numContext1 = sum(rateMatrixContextIds==1);
    numContext2 = sum(rateMatrixContextIds==2);
    
    % Now get the average for 'within' and 'across' contexts. Only use
    % upper triagular to not repeat
    ratesWithin = [];
    ratesAcross = [];
    for i = 1:size(meanRateMatrix,1)
        for j = i+1:size(meanRateMatrix,2)
            c1 = rateMatrixContextIds(i);
            c2 = rateMatrixContextIds(j);
            
            if c1 == c2 % within
                k = length(ratesWithin) + 1;
                ratesWithin(k) = meanRateMatrix(i,j);
            else % across
                k = length(ratesAcross) + 1;
                ratesAcross(k) = meanRateMatrix(i,j);
            end
        end
    end
    meanRatesWithin = nanmean(ratesWithin);
    meanRatesAcross = nanmean(ratesAcross);
    
    
    % Save the data
    outputMatFilename = fullfile(sessionAnalysisFolder, sprintf('%s_compute_average_ratemap_difference_matrix_%s.mat', sessionName, mapNameToUse));
    if isfile(outputMatFilename)
        delete(outputMatFilename);
    end
    save(outputMatFilename, 'meanRateMatrix', 'rateMatrixLabels', 'numContext1', 'numContext2', 'sessionName', 'animalName', 'trialIdToIndex', 'rateMatrices', 'trialIds', 'cellIds', ...
        'rateMatrixContextIds', 'rateMatrixTrialIds', ...
        'ratesWithin', 'ratesAcross', 'meanRatesWithin', 'meanRatesAcross');
    
    

    % Plot
    hFig = figure();
    
    % Matrix plot
    subplot(1,2,1);
    Z = nan(size(meanRateMatrix,1)+1, size(meanRateMatrix,2)+1);
    Z(1:size(meanRateMatrix,1), 1:size(meanRateMatrix,2)) = meanRateMatrix;
    rectangleColour = [0, 0, 0];
    
    %imagesc(meanRateMatrix)
    pcolor(Z)
    shading flat
    axis equal tight
    colormap jet
    colorbar
    xticks(1.5:size(meanRateMatrix,1)+0.5) % center the labels
    yticks(1.5:size(meanRateMatrix,2)+0.5)
    xticklabels(rateMatrixLabels);
    yticklabels(rateMatrixLabels);
    xtickangle(90)
    set(gca, 'ydir', 'reverse')
    % Draw a rectangle aroung only context 1 with context 1
    rectangle('position', [1, 1, numContext1, numContext1], 'Curvature', 0, 'LineWidth', 4, 'EdgeColor', rectangleColour)
    % Draw a rectangle aroung only context 2 with context 2
    rectangle('position', [1+numContext1, 1+numContext1, numContext2, numContext2], 'Curvature', 0, 'LineWidth', 4, 'EdgeColor', rectangleColour)
    %title(sprintf('%s %s\nAverage Fluoresence Rate Difference', animalName, sessionName), 'interpreter', 'none')
    title(sprintf('%s Rate Difference\naveraged across (%d) cells', mapNameToUse, numUniqueCells), 'interpreter', 'none')
    
    % Bar plot
    subplot(1,2,2);
    dataX = [1,2];
    dataY = [meanRatesWithin, meanRatesAcross];
    dataYError = [nanstd(ratesWithin)./sqrt(length(ratesWithin)), nanstd(ratesAcross)./sqrt(length(ratesAcross))];
    
    bar(dataX, dataY);
    hold on
    er = errorbar(dataX,dataY,dataYError,dataYError);    
    er.Color = [0 0 0];                            
    er.LineStyle = 'none';
    er.LineWidth = 2;

    xticks([1,2]);
    xticklabels({'Within', 'Across'});
    
    
    
    title('Mean Rate Difference')
    a = axis;
    %axis([a(1), a(2), 0, max([0.25, a(4)])]);
    
    if APPLY_FILTER
        sgtitle(sprintf('%s %s\nAverage Rate Difference\n(filtered)\nMaps used: %s', animalName, sessionName, mapNameToUse), 'interpreter', 'none')
        %sgtitle('Fluorescence rate differences (filtered)')
    else
        %sgtitle('Fluorescence rate differences (unfiltered)')
        sgtitle(sprintf('%s %s\nAverage Rate Difference\n(unfiltered)\nMaps used: %s', animalName, sessionName, mapNameToUse), 'interpreter', 'none')
    end
    
    outputFigFilename = fullfile(sessionAnalysisFolder, sprintf('%s_compute_%s_rate_difference_matrix.fig', sessionName, mapNameToUse));
    savefig(hFig, outputFigFilename);
    
    outputSvgFilename = fullfile(sessionAnalysisFolder, sprintf('%s_compute_%s_rate_difference_matrix.svg', sessionName, mapNameToUse));
    saveas(hFig, outputSvgFilename);
    
    %close(hFig);

end % function



