function mlgp_create_placemap_database(obj, session)
    fprintf('Creating placemap database (normal) for session %s\n', session.getName());
    
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
        pmf = fullfile(taf, obj.Config.placemaps.outputFolder);

        fl = dir(fullfile(pmf, sprintf('%s*%s', obj.Config.placemaps.filenamePrefix, obj.Config.placemaps.filenameSuffix)));

        if isempty(numCells)
            numCells = length(fl);
        end

        if length(fl) ~= numCells
            error('The number of cells dont match for trial %d but they should!', iTrial)
        end

        cellMaps = [];
        cellTrialIds = nan(numCells,1);
        cellContextIds = nan(numCells,1);
        cellCellIds = nan(numCells,1);

        for iCell = 1:numCells
            pmf = fullfile(fl(iCell).folder, fl(iCell).name);

            % decode the actual name so we don't make a mistake with the cell
            % id
            s = fl(iCell).name;
            s1 = s(length(obj.Config.placemaps.filenamePrefix)+1:end); % strip
            s2 = s1(1:end-length(obj.Config.placemaps.filenameSuffix));
            cellId = str2double(s2);


            tmp = load(pmf);
            pm = tmp.pm.eventMapSmoothed; % this will only work with miniscope

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
    
    ofn = fullfile(session.getAnalysisDirectory(), sprintf('%s_placemaps.mat', session.getName()));
    sessionName = session.getName();
    animalName = obj.Experiment.getAnimalName();

    save(ofn, 'animalName', 'sessionName', 'numTrials', 'numCells', 'maps', 'trialIds', 'contextIds', 'cellIds');
    
    fprintf('\tFinished creating placemap database for session %s\n', session.getName());

end
