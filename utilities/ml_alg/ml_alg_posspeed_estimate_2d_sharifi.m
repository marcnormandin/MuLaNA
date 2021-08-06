function [smoothed_pos_t_s, smoothed_pos_x_cm, smoothed_pos_y_cm, smoothed_speed_cm_s] = ml_alg_posspeed_estimate_2d_sharifi(pos_t_s, pos_x_cm, pos_y_cm, T_s, dmax_cm, maxSpeed_cm_s)

    % Compute the unsmoothed velocity
    dt = diff(pos_t_s);
    dx = diff(pos_x_cm);
    velraw_x = dx ./ dt;
    dy = diff(pos_y_cm);
    velraw_y = dy ./ dt;

    speedraw = sqrt( velraw_x.^2 + velraw_y.^2 );
    badInds = find(speedraw > maxSpeed_cm_s); %union(find(abs(velraw_x) > maxSpeed_cm_s), find(abs(velraw_y) > maxSpeed_cm_s));

    % For each bad index, ADD the neighbouring indices
    badNeighbours = [];
    for i = 1:length(badInds)
        for k = 1:10
            badNeighbours(end+1) = badInds(i)-k;
            badNeighbours(end+1) = badInds(i)+k;
        end
    end
    badInds = union(badInds, badNeighbours);
    badInds(badInds<1) = [];
    badInds(badInds>length(velraw_x)) = [];

    fpos_x_cm = pos_x_cm;
    fpos_y_cm = pos_y_cm;
    fpos_t_s = pos_t_s;

    fpos_x_cm(badInds) = [];
    fpos_y_cm(badInds) = [];
    fpos_t_s(badInds) = [];

    % interpolated coordinates so there is a uniform sampling rate
    % T is the smoothed sampling rate
    ifpos_t_s = pos_t_s(1):T_s:pos_t_s(end);
    ifpos_x_cm = interp1(fpos_t_s, fpos_x_cm, ifpos_t_s);
    ifpos_y_cm = interp1(fpos_t_s, fpos_y_cm, ifpos_t_s);

    [smoothed_pos_x_cm, xvel] = ml_alg_posvel_estimate_1d_sharifi(ifpos_x_cm, T_s, dmax_cm);
    [smoothed_pos_y_cm, yvel] = ml_alg_posvel_estimate_1d_sharifi(ifpos_y_cm, T_s, dmax_cm);

    smoothed_speed_cm_s = sqrt(xvel.^2 + yvel.^2);
    smoothed_pos_t_s = ifpos_t_s;
end