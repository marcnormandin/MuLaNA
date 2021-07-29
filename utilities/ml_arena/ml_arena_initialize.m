function [arena] = ml_arena_initialize(arenaJson, refP, refQ)
        % Example for tetrode roi
        %refP = reshape(arenaroi.inside.j, 1, 4);
        %refQ = reshape(arenaroi.inside.i, 1, 4);
        
        if strcmpi(arenaJson.shape, 'rectangle')
            arena = MLArenaRectangle([refP; refQ], arenaJson.x_length_cm , arenaJson.y_length_cm);
        elseif strcmp(arenaJson.shape, 'square')
            arena = MLArenaSquare([refP; refQ], arenaJson.length_cm);
        elseif strcmp(arenaJson.shape, 'circle')
            arena = MLArenaCircle([refP; refQ], arenaJson.diameter_cm);
        else
            error('Inappropriate shape (%s). Must be square or rectangle', arenaJson.shape);
        end
end
