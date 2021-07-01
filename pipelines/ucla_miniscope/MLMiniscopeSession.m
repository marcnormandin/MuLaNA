classdef MLMiniscopeSession < MLSession
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        CellRegResult;
    end % properties
    
    methods
        function obj = MLMiniscopeSession(config, sessionRecord, name, date, trials, ...
                sessionDirectory, analysisDirectory)
            obj@MLSession(config, sessionRecord, name, date, trials, sessionDirectory, analysisDirectory);
            
            obj.CellRegResult = [];
            
            obj.loadCellRegResult();
        end
        
        function [o] = getCellRegistration(obj)
            % Try to load it if it isn't already loaded
            if isempty(obj.CellRegResult)
                obj.loadCellRegResult();
            end
            o = obj.CellRegResult;
        end
        
        function [b] = hadCellRegistration(obj)
            b = ~isempty(obj.CellRegResult);
        end
        
        function loadCellRegResult(obj)
            cellRegDirectory = fullfile(obj.getAnalysisDirectory(), 'cellreg');
            fl = dir(fullfile(cellRegDirectory, 'cellRegistered*.mat'));
            if isempty(fl)
                warning('No cell registration result found in %s', cellRegDirectory);
                return
            end
            if length(fl) > 1
                error('More than one match for cellRegistered*.mat found in %s', cellRegDirectory);
            end
            tmp = load(fullfile(fl(1).folder, fl(1).name));
            obj.CellRegResult = CellRegistration(tmp.cell_registered_struct);
        end
        
        function [numCells] = getNumCells(obj)
            if obj.hadCellRegistration()
                numCells = obj.CellRegResult.getNumCells();
            else
                numCells = -1;
            end
        end
        
        function [pmlist] = getCellPlacemaps(obj, iCell, placemapType)
            if ~obj.hadCellRegistration()
                error('No cells are registered. Can not return any placemaps.');
            end
            
            if iCell < 1 || iCell > obj.getNumCells()
                error('Can not return placemaps for cell (%d) because there are only (%d) cells.', iCell, obj.getNumCells());
            end
            
            % For the desired iCell, get the map for the cell's ids in each
            % trial that it exists in. The key is the trial number, and the
            % value is the cell id in the respective trial.
            cmap = obj.CellRegResult.getCellMap(iCell);
            
            numMatches = length(cmap);
            
            pmlist = []; %struct('trial_id', [], 'context_id', [], 'cell_id', [], 'placemap', []);

            for iMatch = 1:numMatches
                keys = cmap.keys;
                values = cmap.values;
                iTrial = keys{iMatch};
                iTrialCell = values{iMatch};
                
                warning('This should be getting the trial and needed to be updated. See MLMiniscopeSession::getCellPlacemaps')
                trial = obj.getTrial(iTrial);
                
                
                
                if trial.isEnabled()
                    % Check if the placemap exists
                    % FixMe! We should have the trial itself load the
                    % placemap from file
                    if strcmpi(placemapType, 'actual')
                        fn = fullfile(trial.getAnalysisDirectory(), obj.Config.placemaps.outputFolder, ...
                            sprintf('%s%d%s', obj.Config.placemaps.filenamePrefix, iTrialCell, obj.Config.placemaps.filenameSuffix));
                    elseif strcmpi(placemapType, 'shrunk')
                        fn = fullfile(trial.getAnalysisDirectory(), obj.Config.placemaps.outputFolderShrunk, ...
                            sprintf('%s%d%s', obj.Config.placemaps.filenamePrefix, iTrialCell, obj.Config.placemaps.filenameSuffix));
                    else
                        error('Argument placemapType must be actual or shrunk.\n');
                    end
                    
                    if ~isfile(fn)
                        error('The requested file does not exist: %s\n', fn);
                    end

                    tmp = load(fn);
                    pm = tmp.pm.eventMapSmoothed;
                    if tmp.nid ~= iTrialCell
                        error('Loaded cell (%d) does not match what was intended (%d).\n', nid, iTrialCell);
                    end

                    ind = length(pmlist) + 1;
                    pmlist(ind).trial_id = iTrial;
                    pmlist(ind).context_id = trial.getContextId();
                    pmlist(ind).cell_id = iTrialCell;
                    pmlist(ind).placemap = pm;
                    pmlist(ind).trial_use = trial.isEnabled();
                    pmlist(ind).maps = tmp.pm;
                end
            end % matches across trials
        end % function
        
        function [score] = getCellScore(obj, iCell)
            if ~obj.hadCellRegistration()
                error('No cells are registered. Can not return score.');
            end
            
            if iCell < 1 || iCell > obj.getNumCells()
                error('Can not return score for cell (%d) because there are only (%d) cells.', iCell, obj.getNumCells());
            end
            
            score = obj.CellRegResult.getCellScore(iCell);
        end % function
        
        function [cell_use_list] = getCellUse(obj, iCell)
            if ~obj.hadCellRegistration()
                error('No cells are registered. Can not return any placemaps.');
            end
            
            if iCell < 1 || iCell > obj.getNumCells()
                error('Can not return placemaps for cell (%d) because there are only (%d) cells.', iCell, obj.getNumCells());
            end
            
            % For the desired iCell, get the map for the cell's ids in each
            % trial that it exists in. The key is the trial number, and the
            % value is the cell id in the respective trial.
            cmap = obj.CellRegResult.getCellMap(iCell);
            
            numMatches = length(cmap);
            
            cell_use_list = []; %struct('trial_id', [], 'context_id', [], 'cell_id', [], 'placemap', []);

            for iMatch = 1:numMatches
                keys = cmap.keys;
                values = cmap.values;
                iTrial = keys{iMatch};
                iTrialCell = values{iMatch};
                
                trial = obj.getTrial(iTrial);

                if trial.isEnabled()
                    fn = fullfile(trial.getAnalysisDirectory(), sprintf('cell_use.mat'));
                    if ~isfile(fn)
                        error('The requested file does not exist: %s\n', fn);
                    end

                    tmp = load(fn);
                    cell_use = tmp.cell_use(iTrialCell);
%                     if tmp.nid ~= iTrialCell
%                         error('Loaded cell (%d) does not match what was intended (%d).\n', nid, iTrialCell);
%                     end

                    ind = length(cell_use_list) + 1;
                    cell_use_list(ind).trial_id = iTrial;
                    cell_use_list(ind).context_id = trial.getContextId();
                    cell_use_list(ind).cell_id = iTrialCell;
                    cell_use_list(ind).cell_use = cell_use;
                    cell_use_list(ind).trial_use = trial.isEnabled();
                end
            end % matches across trials
        end % function
        
        function [weightMatrix] = getCellWeightMatrix(obj, iCell)
            if ~obj.hadCellRegistration()
                error('No cells are registered. Can not return weight matrix.');
            end
            
            if iCell < 1 || iCell > obj.getNumCells()
                error('Can not return weight matrix for cell (%d) because there are only (%d) cells.', iCell, obj.getNumCells());
            end
            
            weightMatrix = obj.CellRegResult.getCellWeightMatrix(iCell);
        end % function
        
        function [sfplist] = getCellSpatialFootprints(obj, iCell)
            if ~obj.hadCellRegistration()
                error('No cells are registered. Can not return any placemaps.');
            end
            
            if iCell < 1 || iCell > obj.getNumCells()
                error('Can not return placemaps for cell (%d) because there are only (%d) cells.', iCell, obj.getNumCells());
            end
            
            % For the desired iCell, get the map for the cell's ids in each
            % trial that it exists in. The key is the trial number, and the
            % value is the cell id in the respective trial.
            cmap = obj.CellRegResult.getCellMap(iCell);
            
            numMatches = length(cmap);
            
            sfplist = []; %struct('trial_id', [], 'context_id', [], 'cell_id', [], 'placemap', []);

            cellRegFolder = fullfile(obj.getAnalysisDirectory(), obj.Config.cell_registration.session_sfp_output_folder);
            
            for iMatch = 1:numMatches
                keys = cmap.keys;
                values = cmap.values;
                iTrial = keys{iMatch};
                iTrialCell = values{iMatch};
                
                trial = obj.getTrial(iTrial);
                
                if trial.isEnabled()
                    
                    fn = fullfile(cellRegFolder, sprintf('%s%0.3d.mat', obj.Config.cell_registration.spatialFootprintFilenamePrefix, iTrial));
                    
                    if ~isfile(fn)
                        error('The requested file does not exist: %s\n', fn);
                    end

                    tmp = load(fn);
                    sfp = squeeze(tmp.SFP(iTrialCell,:,:));
                   
                    ind = length(sfplist) + 1;
                    sfplist(ind).trial_id = iTrial;
                    sfplist(ind).context_id = trial.getContextId();
                    sfplist(ind).cell_id = iTrialCell;
                    sfplist(ind).spatial_footprint = sfp;
                    sfplist(ind).trial_use = trial.isEnabled();
                end
            end % matches across trials
        end % function
        
        function [h] = plotCellMaps(obj, iRegCell)
            pmall = obj.getCellPlacemaps(iRegCell, 'actual');

            contextIds = unique([pmall.context_id]);
            numContexts = length(contextIds);
            numContextTrials = zeros(numContexts, 1);
            for iContext = 1:numContexts
                numContextTrials(iContext) = sum([pmall.context_id] == contextIds(iContext));
            end
            numColumns = max(numContextTrials);
            numVerticalPlotsPerTrial = 1; % scatter and placemap
            numRows = numVerticalPlotsPerTrial * numContexts;
            numTotalPlots = numRows * numColumns;

            a = reshape(1:numTotalPlots, numColumns, numRows)';
            plotIndexMap = cell(numContexts, 1);
            for i = 1:numVerticalPlotsPerTrial
                plotIndexMap{i} = a(i:numVerticalPlotsPerTrial:end, :);
            end

            h = figure('name', sprintf('%d', iRegCell));
            ax = [];
            for iContext = 1:numContexts
                pmcm = pmall([pmall.context_id] == contextIds(iContext));
                for iContextMap = 1:length(pmcm)
                    pim1 = plotIndexMap{1};
                    %k = k + 1;

                    k1 = pim1(iContext, iContextMap);

            %         pim2 = plotIndexMap{2};
            %         k2 = pim2(iContext, iContextMap);

                    pm = pmcm(iContextMap).placemap;

                    ax(k1) = subplot(numRows, numColumns, k1);
                    %pm.plot_path_with_spikes()
                    imagesc(pm);
                    colormap jet
                    title(sprintf('T%d', pmcm(iContextMap).trial_id))
                    axis equal off

                    %ax(k2) = subplot(numRows, numColumns, k2);
                    %pm.plot()
                    %imagesc(pm)
                    %title(sprintf('T%d', pmcm(iContextMap).trial_id))
                end % iTrial
            end % iContext

            linkaxes(ax, 'xy')

            axis equal off
        end % function
        
       
        function [h, score] = plotCellSpatialFootprints(obj, iRegCell)
            score = obj.getCellScore(iRegCell);
            sfpList = obj.getCellSpatialFootprints(iRegCell);
            %colors = distinguishable_colors(length(sfpList));
            
            contextIds = unique([sfpList.context_id]);
            numContexts = length(contextIds);
            numContextTrials = zeros(numContexts, 1);
            for iContext = 1:numContexts
                numContextTrials(iContext) = sum([sfpList.context_id] == contextIds(iContext));
            end
            numColumns = max(numContextTrials);
            numVerticalPlotsPerTrial = 1; % scatter and placemap
            numRows = numVerticalPlotsPerTrial * numContexts;
            numTotalPlots = numRows * numColumns;

            a = reshape(1:numTotalPlots, numColumns, numRows)';
            plotIndexMap = cell(numContexts, 1);
            for i = 1:numVerticalPlotsPerTrial
                plotIndexMap{i} = a(i:numVerticalPlotsPerTrial:end, :);
            end

            h = figure('name', sprintf('RegCell: %d, Score: %0.4f', iRegCell, score));
            ax = [];
            for iContext = 1:numContexts
                sfpc = sfpList([sfpList.context_id] == contextIds(iContext));
                for iContextMap = 1:length(sfpc)
                    pim1 = plotIndexMap{1};
                    %k = k + 1;

                    k1 = pim1(iContext, iContextMap);

            %         pim2 = plotIndexMap{2};
            %         k2 = pim2(iContext, iContextMap);

                    sfp = sfpc(iContextMap).spatial_footprint;

                    ax(k1) = subplot(numRows, numColumns, k1);
                    
                    sfpm = ml_core_remove_zero_padding(sfp);
                    imagesc(sfpm)
                    colormap jet
                
                    title(sprintf('T%d', sfpc(iContextMap).trial_id))
                    axis equal off

                    %ax(k2) = subplot(numRows, numColumns, k2);
                    %pm.plot()
                    %imagesc(pm)
                    %title(sprintf('T%d', pmcm(iContextMap).trial_id))
                end % iTrial
            end % iContext

            linkaxes(ax, 'xy')

            axis equal off
            
        end % function
        
        function [h] = plotTrialTracksOnBackground(obj)
            data = struct('trial_id', [], 'context_id', [], 'image', []);
            for iTrial = 1:obj.getNumTrials()
                trial = obj.getTrial(iTrial);
                data(iTrial).trial_id = trial.getTrialId();
                data(iTrial).context_id = trial.getContextId();
                data(iTrial).image = imread(fullfile(trial.getAnalysisDirectory(), 'behavcam_track_pos.png'));
            end
                
            contextIds = unique([data.context_id]);
            numContexts = length(contextIds);
            numContextTrials = zeros(numContexts, 1);
            for iContext = 1:numContexts
                numContextTrials(iContext) = sum([data.context_id] == contextIds(iContext));
            end
            numColumns = max(numContextTrials);
            numVerticalPlotsPerTrial = 1;
            numRows = numVerticalPlotsPerTrial * numContexts;
            numTotalPlots = numRows * numColumns;

            a = reshape(1:numTotalPlots, numColumns, numRows)';
            plotIndexMap = cell(numContexts, 1);
            for i = 1:numVerticalPlotsPerTrial
                plotIndexMap{i} = a(i:numVerticalPlotsPerTrial:end, :);
            end

            h = figure('name', sprintf('Tracks'), 'position', get(0, 'screensize'));
            ax = [];
            for iContext = 1:numContexts
                dc = data([data.context_id] == contextIds(iContext));
                for iContextMap = 1:length(dc)
                    pim1 = plotIndexMap{1};

                    k1 = pim1(iContext, iContextMap);

                    I = dc(iContextMap).image;

                    ax(k1) = subplot(numRows, numColumns, k1);
                    
                    imshow(I)
                
                    title(sprintf('T%d', dc(iContextMap).trial_id))
                    axis off
                end % iTrial
            end % iContext
            
        end % function
        
    end % methods
end

