function compute_fluorescence_rate_scatterplots(obj, session)
    animalName = obj.Experiment.getAnimalName();
    sessionName = session.getName();
    sessionAnalysisFolder = session.getAnalysisDirectory();
    
    % sessionName = session.getName();
    % sessionAnalysisFolder = fullfile('R:\chengs_task_2c\data\minimice\feature_rich', animalName, 'analysis_sat', sessionName);

    % Placemap database
    fnpm = fullfile(sessionAnalysisFolder, sprintf('%s_placemaps.mat', sessionName));
    pmDatabase = load(fnpm);
    maps = pmDatabase.maps;
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

        if strcmpi(obj.Config.placemaps.smoothingProtocol, "Unsmoothed")
            probMapTrials(:,:,iTrial) = pmData.probMap;
        elseif strcmpi(obj.Config.placemaps.smoothingProtocol, "SmoothBeforeDivision") || strcmpi(obj.Config.placemaps.smoothingProtocol, "SmoothAfterDivision")
            probMapTrials(:,:,iTrial) = pmData.probMapSmoothed;
        else
            error("Unknown smoothing protocol. Cannot decide which probability map type to use.");
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
%         cellPreferredRate(cellIdIndices) = 200 + 100*randn(1); %100*randn(length(cellIdIndices),1);
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
%         if cellPreferredContext(k1) == contextId1
%             avgF(k1) = cellPreferredRate(k1)+100; % .* sqrt(0.1+trial1/numTrials);
%         else
%             avgF(k1) = cellPreferredRate(k1); % .* sqrt(0.1+trial1/numTrials);
%         end
%     end
    
    % Now we will filter the data
    % Load the inclusion data
    APPLY_FILTER = obj.Config.calicum_fluorescence_rate_maps.apply_filter_information_content | ...
        obj.Config.calicum_fluorescence_rate_maps.apply_filter_celllike_spatial_footprint;
    if APPLY_FILTER
        inclusionFilename = fullfile(sessionAnalysisFolder, sprintf('%s_placemaps_inclusion.mat', sessionName));
        if isfile(inclusionFilename)
            inclusionData = load(inclusionFilename);
            inclusionData = inclusionData.inclusionData;
            
            inclusion = true(size(avgF));

            if obj.Config.calicum_fluorescence_rate_maps.apply_filter_information_content
                inclusion = inclusion & inclusionData.passedInformationContentFilter;
            end
            
            if obj.Config.calicum_fluorescence_rate_maps.apply_filter_celllike_spatial_footprint
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

    means1 = zeros(numUniqueCells,1);
    means2 = zeros(numUniqueCells,1);
    
    for iCell = 1:numUniqueCells
        cellId = uniqueCellIds(iCell);
        cellInds = find(cellIds == cellId);
        
        cellContexts = contextIds(cellInds);
        cellRates = avgF(cellInds);
        
        rateContext1 = cellRates(cellContexts == 1);
        rateContext2 = cellRates(cellContexts == 2);
        
        m1 = nanmedian(rateContext1);
        m2 = nanmedian(rateContext2);
        
        means1(iCell) = m1;
        means2(iCell) = m2;
    end
    
    figure
    subplot(2,1,1)
    plot(means1, means2, 'ko', 'markerfacecolor', 'r');
    xlabel('Average Mean Fluorescence Rate\nContext 1', 'fontweight', 'bold');
    ylabel('Average Mean Fluorescence Rate\nContext 2', 'fontweight', 'bold');
    grid on
    axis equal
    a = axis;
    hold on
    plot([0, max([a(3),a(4)])], [0, max([a(3), a(4)])], 'k-', 'linewidth', 2)
    title(sprintf('%s %s', animalName, sessionName));
    
    subplot(2,1,2)
    diff = abs(means1 - means2);
    diff(~isfinite(diff)) = [];
    histogram(diff, linspace(0,20,100))
    drawnow
end % function



