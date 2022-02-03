function mlgp_compute_bfo_percell_90(obj, session)
    %fprintf('\tComputing bfo 90 for session %s\n', session.getName());
    
    sessionName = session.getName();
    
    placemapDatabaseFilename = fullfile(session.getAnalysisDirectory(), sprintf('%s_placemaps_shrunk.mat', session.getName()));
    if ~isfile(placemapDatabaseFilename)
        warning('The placemap database file (%s) does not exist. It must be created.', placemapDatabaseFilename);
        return;
    end
    
    rotationsDeg = [0, 90, 180, 270];
    
    % All of the cell ids stored in the placemap database are local to the trial
    placemapData = load(placemapDatabaseFilename);
    
    % We will set the not included maps to be all zeros
    mapType = obj.Config.bfo_percell_90.map_name_to_use;
    maps = placemapData.(mapType);
    
    % Not using shrunk is okay
        % Check if we will apply any filters
    % Load the inclusion data
    placemapsInclude = true(size(maps,3),1); % by default include everything
    APPLY_FILTER = obj.Config.best_fit_orientation.apply_filter_information_content | ...
        obj.Config.best_fit_orientation.apply_filter_celllike_spatial_footprint;
    if APPLY_FILTER
        inclusionFilename = fullfile(session.getAnalysisDirectory(), sprintf('%s_placemaps_inclusion.mat', session.getName()));
        if isfile(inclusionFilename)
            inclusionData = load(inclusionFilename);
            inclusionData = inclusionData.inclusionData;
            
            %inclusion = true(size(avgF));

            if obj.Config.best_fit_orientation.apply_filter_information_content
                placemapsInclude = placemapsInclude & inclusionData.passedInformationContentFilter;
            end
            
            if obj.Config.best_fit_orientation.apply_filter_celllike_spatial_footprint
                placemapsInclude = placemapsInclude & inclusionData.passedCelllikeSpatialFootprintFilter;
            end
        else
            warning('Filtering of cells enabled for fluorescence, but %s is not found so filtering will not be applied.', inclusionFilename);
        end
    end
    
    
    % old version
%     placemapInclusionFilename = fullfile(session.getAnalysisDirectory(), sprintf('%s_placemaps_inclusion.mat', session.getName()));
%     if ~isfile(placemapInclusionFilename)
%         warning('The placemap inclusion database file (%s) does not exist. It must be created.', placemapInclusionFilename);
%         return;
%     end
%     tmp = load(placemapInclusionFilename);
%     placemapsInclude = tmp.inclusionData.include; % should check that ids match the maps
    
    
    % Perform the filtering. We set maps that are not include to all zeros
    % so that the subsequent code does not use them.
    if size(maps,3) ~= length(placemapsInclude)
        error('Inconsistent dimensions. placemap database has (%d) maps, but inclusion database has (%d).\n', size(maps,3), length(placemapsInclude));
    end
    for i = 1:length(placemapsInclude)
       if placemapsInclude(i) == 0
           maps(:,:,i) = zeros(size(maps,1), size(maps,2));
       end
    end
    
    
    
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
    
    [perCell, uniqueCellIds] = ml_algo_bfo_percell_general(maps, cellIds, placemapData.contextIds, placemapData.trialIds, rotationsDeg);
    
    animalName = obj.Experiment.getAnimalName();
        
    numCells = length(uniqueCellIds);
    numTrials = length(unique(placemapData.trialIds));
    numContexts = length(unique(placemapData.contextIds));
    
    save(fullfile(session.getAnalysisDirectory(), sprintf('%s_bfo_percell_90.mat', session.getName())), 'mapType', 'rotationsDeg', 'perCell', 'animalName', 'sessionName', 'numCells', 'uniqueCellIds', 'numTrials', 'numContexts');
end % function
