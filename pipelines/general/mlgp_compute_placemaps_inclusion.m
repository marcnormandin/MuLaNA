function mlgp_compute_placemaps_inclusion(obj, session)
    sessionName = session.getName();
    sessionAnalysisFolder = session.getAnalysisDirectory();

    % Load the map dataset
    placemapData = load(fullfile(sessionAnalysisFolder, sprintf('%s_placemaps.mat', sessionName)));

    % Create the basic structure
    inclusionData.animalName = placemapData.animalName;
    inclusionData.cellIds = placemapData.cellIds;
    inclusionData.contextIds = placemapData.contextIds;
    inclusionData.numCells = placemapData.numCells;
    inclusionData.numTrials = placemapData.numTrials;
    inclusionData.sessionName = placemapData.sessionName;
    inclusionData.trialIds = placemapData.trialIds;

    % By default include all of the maps
    inclusionData.passedInformationContentFilter = true(size(inclusionData.cellIds));

    % Filtering the maps by information content.
    %if obj.Config.placemaps_filtering.information_content_minimum > 0
        icsDataFilename = fullfile(sessionAnalysisFolder, sprintf('%s_ics.mat', sessionName));
        if isfile(icsDataFilename)
            icsData = load(icsDataFilename);

            if ~all((inclusionData.cellIds == icsData.cellIds) & (inclusionData.trialIds == icsData.trialIds) ...
                & (inclusionData.contextIds == icsData.contextIds))
                error('Data is not consistent. Cannot filter by information content.');
            end

            % Filter based on information rate
            minThreshold = obj.Config.calcium_filter_values.information_content.minimum;
            inclusionData.passedInformationContentFilter = icsData.ics >= minThreshold;
        end
    %end

    % Filter the maps by cell-like spatial footprint.
    %if obj.Config.placemaps_filtering.use_celllike_spatial_footprint == 1
    inclusionData.passedCelllikeSpatialFootprintFilter = true(size(inclusionData.cellIds));
        sfpCellLikeFilename = fullfile(sessionAnalysisFolder, sprintf('%s_sfp_celllikes.mat', sessionName));
        if isfile(sfpCellLikeFilename)
            cellLikeData = load(sfpCellLikeFilename);

            if ~all((inclusionData.cellIds == cellLikeData.cellIds) & (inclusionData.trialIds == cellLikeData.trialIds) ...
                & (inclusionData.contextIds == cellLikeData.contextIds))
                error('Data is not consistent. Cannot filter by celllike content.');
            end

            % Filter based on celllike spatial footprint
            inclusionData.passedCelllikeSpatialFootprintFilter = cellLikeData.cellLikes;
        end
    %end

    % Save
    outputFilename = fullfile(sessionAnalysisFolder, sprintf('%s_placemaps_inclusion.mat', sessionName));
    save(outputFilename, 'inclusionData');

end % function
