function mlgp_create_mcmappy_database(obj, session)
    fprintf('Creating mcmappy database (normal) for session %s\n', session.getName());
    
    numTrials = session.getNumTrials();
    numCells = [];

    maps = [];
    trialIds = [];
    contextIds = [];
    cellIds = [];
    traceMaximums = [];
    
    traceMaps = [];
    traceMapsSmoothed = [];
    spikeMaps = [];
    spikeMapsSmoothed = [];
    ilseMaps= [];
    ilseMapsSmoothedBefore = [];
    ilseMapsSmoothedAfter = [];
    eventMaps = [];
    eventMapsSmoothedBefore = [];
    eventMapsSmoothedAfter = [];
    rateMapsMean = [];
    rateMapsStd = [];
            
    % We will also store one spatial probability map per trial
    probMaps = [];
    probMapsSmoothed = [];
    occupancyMaps = [];
    occupancyMapsSmoothed = [];
    pTrialIds = [];
    pContextIds = [];
    
    tstart = tic;

    for iTrial = 1:numTrials
        fprintf('\t\tProcessing trial %d of %d\n', iTrial, numTrials);

        trial = session.getTrialByOrder(iTrial);
        tid = trial.getTrialId();
        cid = trial.getContextId();

        taf = trial.getAnalysisDirectory();
        pmf = fullfile(taf, 'mcmappy.mat');
        
        mcmappy = load(pmf);

        if isempty(numCells)
            numCells = mcmappy.numCells;
        end

        if mcmappy.numCells ~= numCells
            error('The number of cells dont match for trial %d but they should!', iTrial)
        end

        cellMaps = [];
        cellTrialIds = nan(numCells,1);
        cellContextIds = nan(numCells,1);
        cellCellIds = nan(numCells,1);
        cellTraceMaximums = nan(numCells,1);
        

            
        
        for iCell = 1:numCells
            cellId = iCell;
            
            if strcmpi(obj.Config.placemaps.smoothingProtocol, "SmoothBeforeDivision")
                pm = mcmappy.eventMapsSmoothedBefore(:,:,iCell); % this will only work with miniscope
            elseif strcmpi(obj.Config.placemaps.smoothingProtocol, "SmoothAfterDivision")
                pm = mcmappy.eventMapsSmoothedAfter(:,:,iCell); % this will only work with miniscope
            elseif strcmpi(obj.Config.placemaps.smoothingProtocol, "Unsmoothed")
                pm = mcmappy.eventMaps(:,:,iCell); % this will only work with miniscope
            else
                error('Unknown smoothing protocol.')
            end

            
            %pm = mcmappy.eventMaps(:,:,iCell); % this will only work with miniscope
            %pm = mcmappy.eventMapsSmoothedAfter(:,:,iCell); % this will only work with miniscope
            
            if isempty(cellMaps)
                cellMaps = nan(size(pm,1), size(pm,2), numCells);
            end

            cellTraceMaximums(iCell) = mcmappy.traceMaximums(iCell);
            cellMaps(:,:,iCell) = pm;
            cellTrialIds(iCell) = tid;
            cellContextIds(iCell) = cid;
            cellCellIds(iCell) = cellId;
        end

        if isempty(maps)
            traceMaximums = cellTraceMaximums;
            maps = cellMaps;
            trialIds = cellTrialIds;
            contextIds = cellContextIds;
            cellIds = cellCellIds;
            
                        traceMaps = mcmappy.traceMaps;
                    traceMapsSmoothed = mcmappy.traceMapsSmoothed;
                    spikeMaps = mcmappy.spikeMaps;
                    spikeMapsSmoothed = mcmappy.spikeMapsSmoothed;
                    ilseMaps = mcmappy.ilseMaps;
                    ilseMapsSmoothedBefore = mcmappy.ilseMapsSmoothedBefore;
                    ilseMapsSmoothedAfter = mcmappy.ilseMapsSmoothedAfter;
                    eventMaps = mcmappy.eventMaps;
                    eventMapsSmoothedBefore = mcmappy.eventMapsSmoothedBefore;
                    eventMapsSmoothedAfter = mcmappy.eventMapsSmoothedAfter;
                    
                    rateMapsMean = mcmappy.rateMapsMean;
                    rateMapsStd = mcmappy.rateMapsStd;
            
            % per trial maps
            probMaps = mcmappy.probMap;
            probMapsSmoothed = mcmappy.probMapSmoothed;
            occupancyMaps = mcmappy.occupancyMap;
            occupancyMapsSmoothed = mcmappy.occupancyMapSmoothed;
            pTrialIds = tid;
            pContextIds = cid;
    
        else
            traceMaximums = cat(1, traceMaximums, cellTraceMaximums);
            maps = cat(3, maps, cellMaps);
            trialIds = cat(1, trialIds, cellTrialIds);
            contextIds = cat(1, contextIds, cellContextIds);
            cellIds = cat(1, cellIds, cellCellIds);
            
                        traceMaps = cat(3, traceMaps, mcmappy.traceMaps);
                    traceMapsSmoothed = cat(3, traceMapsSmoothed, mcmappy.traceMapsSmoothed);
                    spikeMaps = cat(3, spikeMaps, mcmappy.spikeMaps);
                    spikeMapsSmoothed = cat(3, spikeMapsSmoothed, mcmappy.spikeMapsSmoothed);
                    ilseMaps = cat(3, ilseMaps, mcmappy.ilseMaps);
                    ilseMapsSmoothedBefore = cat(3, ilseMapsSmoothedBefore, mcmappy.ilseMapsSmoothedBefore);
                    ilseMapsSmoothedAfter = cat(3, ilseMapsSmoothedAfter, mcmappy.ilseMapsSmoothedAfter);
                    eventMaps = cat(3, eventMaps, mcmappy.eventMaps);
                    eventMapsSmoothedBefore = cat(3, eventMapsSmoothedBefore, mcmappy.eventMapsSmoothedBefore);
                    eventMapsSmoothedAfter = cat(3, eventMapsSmoothedAfter, mcmappy.eventMapsSmoothedAfter);
                    
                    rateMapsMean = cat(3, rateMapsMean, mcmappy.rateMapsMean);
                    rateMapsStd = cat(3, rateMapsStd, mcmappy.rateMapsStd);

                    
            % per trial maps
            probMaps = cat(3, probMaps, mcmappy.probMap);
            probMapsSmoothed = cat(3, probMapsSmoothed, mcmappy.probMapSmoothed);
            occupancyMaps = cat(3, occupancyMaps, mcmappy.occupancyMap);
            occupancyMapsSmoothed = cat(3, occupancyMapsSmoothed, mcmappy.occupancyMapSmoothed);
            pTrialIds = cat(1, pTrialIds, tid);
            pContextIds = cat(1, pContextIds, cid);
        end
    end
    telapsed = toc(tstart);
    fprintf('\tProcessed %s in %0.2f mins\n', session.getName(), telapsed/60.0);
    
    % Save the main file that has maps per cell
    ofn = fullfile(session.getAnalysisDirectory(), sprintf('%s_placemaps.mat', session.getName()));
    sessionName = session.getName();
    animalName = obj.Experiment.getAnimalName();
    save(ofn, 'animalName', 'sessionName', 'numTrials', 'numCells', 'maps', 'trialIds', 'contextIds', 'cellIds', 'traceMaximums', ...
                'traceMaps', 'traceMapsSmoothed', ...
        'spikeMaps', 'spikeMapsSmoothed', ...
        'ilseMaps', 'ilseMapsSmoothedBefore', 'ilseMapsSmoothedAfter', ...
        'eventMaps', 'eventMapsSmoothedBefore', 'eventMapsSmoothedAfter', ...
        'rateMapsMean', 'rateMapsStd');
    
    % Save the main file that has maps per trial
    trialIds = pTrialIds;
    contextIds = pContextIds;
    ofn = fullfile(session.getAnalysisDirectory(), sprintf('%s_trialmaps.mat', session.getName()));
    sessionName = session.getName();
    animalName = obj.Experiment.getAnimalName();
    save(ofn, 'animalName', 'sessionName', 'numTrials', 'trialIds', 'contextIds', ...
                'probMaps', 'probMapsSmoothed', ...
                'occupancyMaps', 'occupancyMapsSmoothed');
    
    
    fprintf('\tFinished creating placemap database for session %s\n', session.getName());

end
