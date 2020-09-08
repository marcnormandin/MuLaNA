classdef MLMiniscopeSession < MLSession
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        CellRegResult;
    end % properties
    
    methods
        function obj = MLMiniscopeSession(config, name, date, trials, ...
                sessionDirectory, analysisDirectory)
            obj@MLSession(config, name, date, trials, sessionDirectory, analysisDirectory);
            
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
        
    end % methods
end

