classdef CellRegistration
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        CellRegisteredStruct
    end
    
    methods
        function obj = CellRegistration(cellRegisteredStruct)
            obj.CellRegisteredStruct = cellRegisteredStruct;
        end
        
        function [n] = getNumCells(obj)
            n = size(obj.CellRegisteredStruct.cell_to_index_map, 1);
        end
        
        function [n] = getNumMatchesForCell(obj, iCell)
            if iCell < 1 || iCell > obj.getNumCells()
                error('Invalid cell number');
            end
            l = obj.CellRegisteredStruct.cell_to_index_map(iCell,:);
            n = length(find(l ~= 0));
        end
        
        function [b] = hasMatches(obj, iCell)
            if obj.getNumMatchesForCell(iCell) > 1
                b = true;
            else
                b = false;
            end
        end
        
        function [m] = getCellMap(obj, iCell)
            if iCell < 1 || iCell > obj.getNumCells()
                error('Invalid cell number');
            end
            l = obj.CellRegisteredStruct.cell_to_index_map(iCell,:);
            m = containers.Map('KeyType', 'double', 'ValueType', 'double');
            for i = 1:length(l)
                if l(i) ~= 0
                    m(i) = l(i);
                end
            end
        end
        
        function [score] = getCellScore(obj, iCell)
            if iCell < 1 || iCell > obj.getNumCells()
                error('Invalid cell number');
            end
            score = obj.CellRegisteredStruct.cell_scores(iCell);
        end
        
        function [weightMatrix] = getCellWeightMatrix(obj, iCell)
            if iCell < 1 || iCell > obj.getNumCells()
                error('Invalid cell number');
            end
            weightMatrix = obj.CellRegisteredStruct.p_same_registered_pairs{iCell};
        end
        
    end
end

