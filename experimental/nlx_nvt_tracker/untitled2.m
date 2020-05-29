close all

x_cm = movement.x_cm;
y_cm = movement.y_cm;
timestamps_ms = movement.timestamps_ms;

% This computes the speed and then smoothes it
   
    % Convert from microseconds to seconds
    timestamps_s = timestamps_ms ./ 10^3;
    
    % Compute the velocity components in cm / second
    dx = diff(x_cm);
    dy = diff(y_cm);
    dt = median(diff(timestamps_s));
    
    % Velocity components (cm per s)
    vx = dx./dt;
    vy = dy./dt;
    
    % Unsmoothed speed (cm per s)
    speed_cm_per_s = sqrt( vx.^2 + vy.^2 );

    figure
    hist(dx, 100)
    title('dx')
    figure
    hist(dy, 100)
    title('dy')
    figure
    hist(dt, 100)
    title('dt')
    