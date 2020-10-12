function [x_cm, y_cm, arena] = ml_core_compute_canon_coordinates(arenaRoi_x_px, arenaRoi_y_px, arenaLengthCm, x_px, y_px )
        % Construct the appropriate arena. All the shapes have 4 control
        % points that serve as references.
        refP = reshape(arenaRoi_x_px, 1, 4);
        refQ = reshape(arenaRoi_y_px, 1, 4);
        if length(arenaLengthCm) == 2
            arena = MLArenaRectangle([refP; refQ], arenaLengthCm(1) , arenaLengthCm(2));
        elseif length(arenaLengthCm) == 1
            arena = MLArenaSquare([refP; refQ], arenaLengthCm);
        else
            error('Inappropriate shape. Must be square or rectangle');
        end

        % Transform positions from video to canonical (pixels to
        % cm)
        [x_cm, y_cm] = arena.tranformVidToCanonPoints(x_px, y_px);
end