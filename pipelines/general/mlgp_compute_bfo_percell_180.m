function mlgp_compute_bfo_percell_180(obj, session)
    %fprintf('\tComputing bfo 180 for session %s\n', session.getName());
    
    sessionName = session.getName();
    
    placemapDatabaseFilename = fullfile(session.getAnalysisDirectory(), sprintf('%s_placemaps.mat', session.getName()));
    if ~isfile(placemapDatabaseFilename)
        warning('The placemap database file (%s) does not exist. It must be created.', placemapDatabaseFilename);
        return;
    end
    
    rotationsDeg = [0, 180];
    
    placemapData = load(placemapDatabaseFilename);
    
    % Because the miniscope cell data could be run as separate trials,
    % instead of being concatenated, we need to use the cell registration
    % structure. Tetrode data doesn't have that issue so we just use the
    % same cell ids.
    localCellIds = placemapData.cellIds;
    cellIds = nan(length(localCellIds), 1);
    if isa(obj, 'MLMiniscopePipeline')
        % Note to implement the mapping to global ids using the cell registration    
        cellReg = session.getCellRegistration();
        cmap = cellReg.CellRegisteredStruct.cell_to_index_map;
        
        if length(cellIds) ~= length(placemapData.trialIds)
            error('CellIds and TrialIds should be a one-to-one list.');
        end
        
        % Map from local cell ids to the global ids using the cell
        % registration map
        for k = 1:length(localCellIds)
           % there COULD BE the off chance that there is not one-to-one
           % correspondence, so we need to check.
           
           %1) Get the trial column
           colData = cmap(:, placemapData.trialIds(k));
           
           %2) Find matching id
           imatch = find(colData == localCellIds(k));
           
           if isempty(imatch)
               error('Unable to find a matching global cell id');
           elseif length(imatch) > 1
               error('Found more than one global id for the combination of (trial cell id, trial id), so the cellregistration is poor.');
           end
           
           % We found one only match, great!
           cellIds(k) = colData(imatch);
        end
    else % tetrodes so no need to do any mapping
       cellIds = localCellIds; 
    end
    
    [perCell, uniqueCellIds] = ml_algo_bfo_percell_general(placemapData.maps, cellIds, placemapData.contextIds, placemapData.trialIds, rotationsDeg);
    
    animalName = obj.Experiment.getAnimalName();
        
    numCells = length(uniqueCellIds);
    numTrials = length(unique(placemapData.trialIds));
    numContexts = length(unique(placemapData.contextIds));
    
    save(fullfile(session.getAnalysisDirectory(), sprintf('%s_bfo_percell_180.mat', session.getName())), 'rotationsDeg', 'perCell', 'animalName', 'sessionName', 'numCells', 'uniqueCellIds', 'numTrials', 'numContexts');
end % function
