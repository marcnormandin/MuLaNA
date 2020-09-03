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
        
    end % methods
end

