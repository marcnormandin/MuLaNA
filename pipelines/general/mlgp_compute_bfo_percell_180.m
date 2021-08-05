function mlgp_compute_bfo_percell_180(obj, session)
    fprintf('\tComputing bfo 180 for session %s\n', session.getName());
    
    sessionName = session.getName();
    
    placemapDatabaseFilename = fullfile(session.getAnalysisDirectory(), sprintf('%s_placemaps.mat', session.getName()));
    if ~isfile(placemapDatabaseFilename)
        warning('The placemap database file (%s) does not exist. It must be created.', placemapDatabaseFilename);
        return;
    end
    
    rotationsDeg = [0, 180];
    
    placemapData = load(placemapDatabaseFilename);

    [perCell, uniqueCellIds] = ml_algo_bfo_percell_general(placemapData.maps, placemapData.cellIds, placemapData.contextIds, placemapData.trialIds, rotationsDeg);
    
    animalName = obj.Experiment.getAnimalName();
        
    numCells = length(uniqueCellIds);
    numTrials = length(unique(placemapData.trialIds));
    numContexts = length(unique(placemapData.contextIds));
    
    save(fullfile(session.getAnalysisDirectory(), sprintf('%s_bfo_percell_180.mat', session.getName())), 'rotationsDeg', 'perCell', 'animalName', 'sessionName', 'numCells', 'uniqueCellIds', 'numTrials', 'numContexts');
end % function
