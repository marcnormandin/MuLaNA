function [other_x_cm, other_y_cm] = mulana_transform_other_roi(arenaJson, arenaroi)
        refP = reshape(arenaroi.inside.j, 1, 4);
        refQ = reshape(arenaroi.inside.i, 1, 4);
        if strcmpi(arenaJson.shape, 'rectangle')
            arena = MLArenaRectangle([refP; refQ], arenaJson.x_length_cm , arenaJson.y_length_cm);
        elseif strcmp(arenaJson.shape, 'square')
            arena = MLArenaSquare([refP; refQ], arenaJson.length_cm);
        elseif strcmp(arenaJson.shape, 'circle')
            arena = MLArenaCircle([refP; refQ], arenaJson.diameter_cm);
        else
            error('Inappropriate shape (%s). Must be square or rectangle', arenaJson.shape);
        end

        % Transform positions from video to canonical (pixels to
        % cm)
        numOther = length(arenaroi.other.i);
        other_x_cm = zeros(1, numOther);
        other_y_cm = zeros(1, numOther);
        for iOther = 1:numOther
            x_px = arenaroi.other.j(iOther);
            y_px = arenaroi.other.i(iOther);
            [other_x_cm(iOther), other_y_cm(iOther)] = arena.tranformVidToCanonPoints(x_px, y_px);
        end %iOther
        
end % function