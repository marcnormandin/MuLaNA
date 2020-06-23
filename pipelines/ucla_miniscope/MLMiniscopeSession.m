classdef MLMiniscopeSession < MLSession
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        CellRegResult;
    end % properties
    
    methods
        function obj = MLMiniscopeSession(name, date, trials, ...
                sessionDirectory, analysisDirectory)
            obj@MLSession(name, date, trials, sessionDirectory, analysisDirectory);
            
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
    end % methods
end

