function create_sfp_celllike_database(obj, session)
    fprintf('Creating spatial footprint (sfp) cell-like database for session %s\n', session.getName());
    
    numTrials = session.getNumTrials();
    
    % Load the cell-like data for each trial
    trialSfpCellLike = cell(numTrials,1);
    for iTrial = 1:numTrials
        fprintf('\t\tProcessing trial %d of %d\n', iTrial, numTrials);

        trial = session.getTrialByOrder(iTrial);
        taf = trial.getAnalysisDirectory();
        
        clfn = fullfile(taf, 'sfp_celllike.mat');
        if ~isfile(clfn)
            warning('%s is not present. can not make database.', clfn);
            return
        end
        
        tmp = load(clfn);
        trialSfpCellLike{iTrial} = tmp.sfpCellLike;
    end
    
    % cmap has #cells rows and #trials cols
    cellReg = session.getCellRegistration();
    cmap = cellReg.CellRegisteredStruct.cell_to_index_map;
    
    numGlobalCells = size(cmap,1);
    if size(cmap,2) ~= numTrials
        error('Logic error. Number of trials from pipeline (%d) dont match those in the cellreg (%d). Abandon all hope.', numTrials, size(cmap,2));
    end
    
    sfp_celllike_global = zeros(numGlobalCells,1);
    for iGlobalCell = 1:numGlobalCells
       cl = true(1, numTrials);
       for iTrial = 1:numTrials
          localCellId = cmap(iGlobalCell, iTrial);
          tmp = trialSfpCellLike{iTrial};
          cl(iTrial) = tmp(localCellId);
       end
       
       % If scored more as cell-like, then score it as cell-like
       if sum(cl == true, 'all') >= sum(cl == false, 'all')
           sfp_celllike_global(iGlobalCell) = true;
       else
           sfp_celllike_global(iGlobalCell) = false;
       end
    end
    
    ofn = fullfile(session.getAnalysisDirectory(), sprintf('%s_sfp_celllike.mat', session.getName()));
    animalName = obj.Experiment.getAnimalName();
    sessionName = session.getName();

    save(ofn, 'animalName', 'sessionName', 'numTrials', 'numGlobalCells', 'cmap', 'sfp_celllike_global');
    
    fprintf('\tFinished creating placemap database for session %s\n', session.getName());

end
