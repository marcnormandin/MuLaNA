function [Z] = ml_bs_occupancy_xy(bs, x, y)
    % Computes the occupancy for the positions in (x,y)
    Z = ml_bs_accumulate_xy(bs, x, y, 1);
end
