function [speed_cm_per_s, speed_smoothed_cm_per_s, vx, vy, vx_smoothed, vy_smoothed] ...
    = ml_core_compute_motion(x_cm, y_cm, timestamps_ms, velocity_lowpass_wpass)

    % This computes the speed and then smoothes it
    
    % Convert from microseconds to seconds
    timestamps_s = timestamps_ms ./ 10^3;
    
    % Compute the velocity components in cm / second
    dx = diff(x_cm);
    dy = diff(y_cm);
    dt = diff(timestamps_s);
    
    % Timestamps can be identical (rate), so find any where dt is there and
    % replace it with the median
    badi = find(dt == 0);
    if ~isempty(badi)
        dt(badi) = median(dt, 'all');
    end
    
    % Velocity components (cm per s)
    vx = dx./dt;
    vy = dy./dt;
    
    % Unsmoothed speed (cm per s)
    speed_cm_per_s = sqrt( vx.^2 + vy.^2 );

    
    % Smoothed velocity components (cm per s)
    vx_smoothed = lowpass(vx, velocity_lowpass_wpass);
    vy_smoothed = lowpass(vy, velocity_lowpass_wpass);

    % Smoothed speed (cm per s)
    speed_smoothed_cm_per_s = sqrt( vx_smoothed.^2 + vy_smoothed.^2 );
    
    % Because of the rates, all of the vectors have one less element so we
    % add a first element to make the arrays the same length. We assume
    % that the values at the second timestamp are the same as the first
    % timestamp.
    vx = [vx(1), vx];
    vy = [vy(1), vy];
    speed_cm_per_s = [speed_cm_per_s(1), speed_cm_per_s];
    vx_smoothed = [vx_smoothed(1), vx_smoothed];
    vy_smoothed = [vy_smoothed(1), vy_smoothed];
    speed_smoothed_cm_per_s = [speed_smoothed_cm_per_s(1), speed_smoothed_cm_per_s];
end % function
