function [Z] = ml_bs_probxy_xy(bs, x, y)
    % Compute the probability for the positions in (x,y)
    Z = ml_bs_accumulate_xy(bs, x,y, 1);
    s = nansum(Z, 'all');
    Z = Z ./ s;
    Z(isnan(Z)) = 0;
end