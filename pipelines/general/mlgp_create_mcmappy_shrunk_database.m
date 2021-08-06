function mlgp_create_mcmappy_shrunk_database(obj, session)
    fprintf('Creating mcmappy database (shrunk) for session %s\n', session.getName());
    
    numTrials = session.getNumTrials();
    numCells = [];

    maps = [];
    trialIds = [];
    contextIds = [];
    cellIds = [];

    tstart = tic;

    for iTrial = 1:numTrials
        fprintf('\t\tProcessing trial %d of %d\n', iTrial, numTrials);

        trial = session.getTrialByOrder(iTrial);
        tid = trial.getTrialId();
        cid = trial.getContextId();

        taf = trial.getAnalysisDirectory();
        pmf = fullfile(taf, 'mcmappy_shrunk.mat');
        
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

        for iCell = 1:numCells
            cellId = iCell;
            
            pm = mcmappy.eventMapsSmoothedAfter(:,:,iCell); % this will only work with miniscope

            if isempty(cellMaps)
                cellMaps = nan(size(pm,1), size(pm,2), numCells);
            end

            cellMaps(:,:,iCell) = pm;
            cellTrialIds(iCell) = tid;
            cellContextIds(iCell) = cid;
            cellCellIds(iCell) = cellId;
        end

        if isempty(maps)
            maps = cellMaps;
            trialIds = cellTrialIds;
            contextIds = cellContextIds;
            cellIds = cellCellIds;
        else
            maps = cat(3, maps, cellMaps);
            trialIds = cat(1, trialIds, cellTrialIds);
            contextIds = cat(1, contextIds, cellContextIds);
            cellIds = cat(1, cellIds, cellCellIds);
        end
    end
    telapsed = toc(tstart);
    fprintf('\tProcessed %s in %0.2f mins\n', session.getName(), telapsed/60.0);
    
    ofn = fullfile(session.getAnalysisDirectory(), sprintf('%s_placemaps_shrunk.mat', session.getName()));
    sessionName = session.getName();
    animalName = obj.Experiment.getAnimalName();

    save(ofn, 'animalName', 'sessionName', 'numTrials', 'numCells', 'maps', 'trialIds', 'contextIds', 'cellIds');
    
    fprintf('\tFinished creating mcmappy (shrunk) database for session %s\n', session.getName());

end
