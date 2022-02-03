function mlgp_create_sfp_celllike_database(obj, session)
    fprintf('Creating spatial footprint (sfp) celllike database (one sfp per placemap) for session %s\n', session.getName());
    
    % This create an array database that has one sfp classification
    % per neuron, per trial for one session.
    
    numTrials = session.getNumTrials();
    numCells = [];

    cellLikes = [];
    trialIds = [];
    contextIds = [];
    cellIds = [];

    tstart = tic;

    for iTrial = 1:numTrials
        fprintf('\t\tProcessing trial %d of %d\n', iTrial, numTrials);

        trial = session.getTrialByOrder(iTrial);
        tid = trial.getTrialId();
        cid = trial.getContextId();

        % Get the filename
        taf = trial.getAnalysisDirectory();
        sfpCellLikeFilename = fullfile(taf, 'sfp_celllike.mat');
        if ~isfile(sfpCellLikeFilename)
            error('Unable to load file (%s) as it does not exist.', sfpCellLikeFilename);
        end
        
        tmp = load(sfpCellLikeFilename);
        trialCellLike = tmp.sfpCellLike;
        
        trialNumCells = length(trialCellLike);
        
%         if isempty(numCells)
%             numCells = length(trialCellLike);
%         end

%         if mcmappy.numCells ~= numCells
%             error('The number of cells dont match for trial %d but they should!', iTrial)
%         end

        % Arrays for the current trial
        cellLike = nan(trialNumCells,1);
        cellTrialIds = nan(trialNumCells,1);
        cellContextIds = nan(trialNumCells,1);
        cellCellIds = nan(trialNumCells,1);

        for iCell = 1:trialNumCells
            cellId = iCell;
           
            cellLike(iCell) = trialCellLike(iCell);
            cellTrialIds(iCell) = tid;
            cellContextIds(iCell) = cid;
            cellCellIds(iCell) = cellId;
        end

        if isempty(cellLikes)
            cellLikes = cellLike;
            trialIds = cellTrialIds;
            contextIds = cellContextIds;
            cellIds = cellCellIds;
        else
            cellLikes = cat(1, cellLikes, cellLike);
            trialIds = cat(1, trialIds, cellTrialIds);
            contextIds = cat(1, contextIds, cellContextIds);
            cellIds = cat(1, cellIds, cellCellIds);
        end
    end
    telapsed = toc(tstart);
    fprintf('\tProcessed %s in %0.2f mins\n', session.getName(), telapsed/60.0);
    
    ofn = fullfile(session.getAnalysisDirectory(), sprintf('%s_sfp_celllikes.mat', session.getName()));
    sessionName = session.getName();
    animalName = obj.Experiment.getAnimalName();

    save(ofn, 'animalName', 'sessionName', 'numTrials', 'cellLikes', 'trialIds', 'contextIds', 'cellIds');
    
    fprintf('\tFinished creating celllike database for session %s\n', session.getName());

end
