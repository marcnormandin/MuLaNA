function [t_s, pos_x_cm, pos_y_cm] = ml_sim_random_walk_rectangle(boundsx_cm, boundsy_cm, totalTime_s, samplingRate_hz)
    % This code simulates a random walk confined to a rectangular area.
    % The path simulation code performs a random walk with intermitent attraction to one
    % of the 4 cups so that the paths are more realistic to what we see with real data.
    
    dt_s = 1/samplingRate_hz;
    t_s = 0:dt_s:totalTime_s;
    totalTime_s = t_s(end);
    numSamples = length(t_s);

    pos_x_cm = zeros(1, numSamples);
    pos_y_cm = zeros(1, numSamples);

    % These numbers should be more general.
    pos_x_cm(1) = 10;
    pos_y_cm(1) = 15;
    vel_x_cps = 1;
    vel_y_cps = 1;
    SPEED_MAX_CPS = 5;

    % The center of the cups are the 4 attractors. Assumes the 30x20cm
    % rectangle, so the code should be generalized when that is no longer
    % the case (for the future). Or just send in the attractors.
    attractors = [ 15,5; 5,5; 5, 25; 15, 25];
    
    % This simulates random attractors being on (one at a time), and then being
    % off for another amount of time.
    numAttractors = size(attractors,1);
    attractor_time_on = 20; % 20 seconds on and then 10 seconds off.
    attractor_time_off = 10;
    attractor_ind_s = zeros(1, numSamples);
    tCurrent = t_s(1);    
    while tCurrent < t_s(end)
       aCurrent = randi(numAttractors);
       aCurrent_time_on_s = attractor_time_on + 10*randn(1);
       aCurrent_time_off_s = attractor_time_off + 10*randn(1);
       
       indOn = intersect(find(t_s >= tCurrent), find(t_s <= tCurrent + aCurrent_time_on_s));
       indOff = intersect(find(t_s >= tCurrent + aCurrent_time_on_s), find(t_s <= tCurrent + aCurrent_time_on_s + aCurrent_time_off_s));
       
       attractor_ind_s(indOn) = aCurrent;
       attractor_ind_s(indOff) = 0;
       
       if isempty(indOn) || isempty(indOff)
           break;
       else
            tCurrent = t_s(indOff(end));
       end
    end
    
    % Perform the random walk with the addition of the attractors. The
    % paths are confined by bouncing off of the walls by mirroring the
    % velocity vector.
    for iSample = 2:numSamples
        vel_x_cps = vel_x_cps + (randi(3)-2)*randn(1);
        vel_y_cps = vel_y_cps + (randi(3)-2)*randn(1);
        mag = sqrt(vel_x_cps.^2 + vel_y_cps.^2);
        r = 1; %rand(1);
        vel_x_cps = vel_x_cps ./ mag * SPEED_MAX_CPS * r;
        vel_y_cps = vel_y_cps ./ mag * SPEED_MAX_CPS * r;
        
        % Add push toward a possible active attractor
        if attractor_ind_s(iSample) ~= 0
            dx = pos_x_cm(iSample-1) - attractors(attractor_ind_s(iSample),1);
            dy = pos_y_cm(iSample-1) - attractors(attractor_ind_s(iSample),2);
            theta = atan2(dy, dx);
            speed_cps = sqrt(vel_x_cps.^2 + vel_y_cps.^2);
            
            distance = sqrt(dx.^2 + dy.^2);
            if distance > 2
                attractor_percent = 0.2;
                vel_x_cps = vel_x_cps - speed_cps*attractor_percent*cos(theta);
                vel_y_cps = vel_y_cps - speed_cps*attractor_percent*sin(theta);
            end
        end

        px = pos_x_cm(iSample-1) + vel_x_cps*dt_s;
        if px <= boundsx_cm(1) || px >= boundsx_cm(2)
            vel_x_cps = -1 * vel_x_cps;
            px = pos_x_cm(iSample-1) + vel_x_cps*dt_s;
        end

        py = pos_y_cm(iSample-1) + vel_y_cps*dt_s;
        if py <= boundsy_cm(1) || py >= boundsy_cm(2)
            vel_y_cps = -1 * vel_y_cps;
            py = pos_y_cm(iSample-1) + vel_y_cps*dt_s;
        end

        pos_x_cm(iSample) = px;
        pos_y_cm(iSample) = py;
    end % iSample
end % function