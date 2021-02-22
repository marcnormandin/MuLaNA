function [cx, cy] = ml_util_transform_px_to_cm(tx, ty, length_short_cm, length_long_cm)
    [r] = ml_util_minimum_bounding_box(tx, ty);
    [qx, qy] = ml_util_minimum_bounding_box_map(r, tx, ty);
    [rx, ry] = ml_util_minimum_bounding_box_map(r, r(:,1), r(:,2));

    % Can only have two different lengths for the edges
    l1 = rx(2) - rx(1);
    l2 = ry(3) - ry(2);
    length_short_pixels = l1;
    length_long_pixels = l2;

    if l1 > l2
        %fprintf('swapping\n')
        % rotate so that the smallest length is horizontal
        % which is the standard (feature would be on the top or bottom)
        tmpx = qx;
        tmpy = qy;
        qy = tmpx;
        qx = -tmpy + l2; % make positive again

        tmpx = rx;
        tmpy = ry;
        rx = -tmpy + l2; % make positive again
        ry = tmpx;

        length_short_pixels = l2;
        length_long_pixels = l1;
    end
    % Because of the numerics, bound the positions
    qx(qx < 0) = 0;
    qy(qy < 0) = 0;
    rx(rx < 0) = 0;
    ry(ry < 0) = 0;
    qx(qx > length_short_pixels) = length_short_pixels;
    qy(qy > length_long_pixels) = length_long_pixels;
    rx(rx > length_short_pixels) = length_short_pixels;
    ry(ry > length_long_pixels) = length_long_pixels;

    % Transform pixels to centimeters
    cx = qx / length_short_pixels * length_short_cm;
    cy = qy / length_long_pixels * length_long_cm;

end % function
