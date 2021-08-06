function mlgp_create_climerics_database(obj, session)
    fprintf('Creating ics database for session %s\n', session.getName());
    
    numTrials = session.getNumTrials();
    numCells = [];

    ics = [];
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
        pmf = fullfile(taf, 'climerICS_smoothed.mat');
        
        tmp = load(pmf);
        climerICS = tmp.climerICS_smoothed;

        if isempty(numCells)
            numCells = length(climerICS);
        end

        if length(climerICS) ~= numCells
            error('The number of cells dont match for trial %d but they should!', iTrial)
        end

        cellICS = [];
        cellTrialIds = nan(numCells,1);
        cellContextIds = nan(numCells,1);
        cellCellIds = nan(numCells,1);

        for iCell = 1:numCells
            cellId = iCell;
            
            pm = climerICS(iCell); % this will only work with miniscope

            if isempty(cellICS)
                cellICS = nan(numCells,1);
            end

            cellICS(iCell) = pm;
            cellTrialIds(iCell) = tid;
            cellContextIds(iCell) = cid;
            cellCellIds(iCell) = cellId;
        end

        if isempty(ics)
            ics = cellICS;
            trialIds = cellTrialIds;
            contextIds = cellContextIds;
            cellIds = cellCellIds;
        else
            ics = cat(1, ics, cellICS);
            trialIds = cat(1, trialIds, cellTrialIds);
            contextIds = cat(1, contextIds, cellContextIds);
            cellIds = cat(1, cellIds, cellCellIds);
        end
    end
    telapsed = toc(tstart);
    fprintf('\tProcessed %s in %0.2f mins\n', session.getName(), telapsed/60.0);
    
    ofn = fullfile(session.getAnalysisDirectory(), sprintf('%s_ics.mat', session.getName()));
    sessionName = session.getName();
    animalName = obj.Experiment.getAnimalName();

    save(ofn, 'animalName', 'sessionName', 'numTrials', 'numCells', 'ics', 'trialIds', 'contextIds', 'cellIds');
    
    fprintf('\tFinished creating ics database for session %s\n', session.getName());

end
