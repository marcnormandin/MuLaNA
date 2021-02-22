function [movement] = mulana_compute_movement(arenaJson, arenaroi, x_px, y_px, timestamps_ms)
velocity_lowpass_wpass = 0.05;

timestamps_ms = reshape(timestamps_ms, 1, length(timestamps_ms));
% Construct the appropriate arena. All the shapes have 4 control
        % points that serve as references.
        refP = reshape(arenaroi.inside.j, 1, 4);
        refQ = reshape(arenaroi.inside.i, 1, 4);
        if strcmpi(arenaJson.shape, 'rectangle')
            arena = MLArenaRectangle([refP; refQ], arenaJson.x_length_cm , arenaJson.y_length_cm);
        elseif strcmpi(arenaJson.shape, 'square')
            arena = MLArenaSquare([refP; refQ], arenaJson.length_cm);
        elseif strcmpi(arenaJson.shape, 'circle')
            arena = MLArenaCircle([refP; refQ], arenaJson.diameter_cm);
        else
            error('Inappropriate shape (%s). Must be square, rectangle, or circle.', arenaJson.shape);
        end

        % Transform positions from video to canonical (pixels to
        % cm)
        [x_cm, y_cm] = arena.tranformVidToCanonPoints(x_px, y_px);

        % Compute the speed in the canonical frame (in cm/s)
        [speed_cm_per_s, speed_smoothed_cm_per_s, vx, vy, vx_smoothed, vy_smoothed] ...
            = ml_core_compute_motion(x_cm, y_cm, timestamps_ms, velocity_lowpass_wpass);

        % Store the values to be saved
        movement.arena = arena;
        movement.arenaShape = arena.getShapeType();
        [movement.boundsX, movement.boundsY] = arena.getCanonicalBounds();
        movement.x_px = x_px; % store the video coordinates
        movement.y_px = y_px; % store the video coordinates
        movement.x_cm = x_cm;
        movement.y_cm = y_cm;
        movement.isInsideArena = arena.inInterior( x_cm, y_cm );
        movement.timestamps_ms = timestamps_ms;
        movement.speed_cm_per_s = speed_cm_per_s;
        movement.speed_smoothed_cm_per_s = speed_smoothed_cm_per_s;
        movement.vx = vx;
        movement.vy = vy;
        movement.vx_smoothed = vx_smoothed;
        movement.vy_smoothed = vy_smoothed;
        
end % function
