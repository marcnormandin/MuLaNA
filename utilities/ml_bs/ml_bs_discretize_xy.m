function [xj, yj] = ml_bs_discretize_xy(bs, x, y)
    if size(x,1) ~= 1 && size(x,2) ~= 1
        error('Invalid size of x. Should be 1xN.');
    end
    
    if size(y,1) ~= 1 && size(y,2) ~= 1
        error('Invalid size of y. Should be 1xN');
    end
    
    if size(x,1) ~= 1
        x = reshape(x, 1, numel(x));
    end
    
    if size(y,1) ~= 1
        y = reshape(y, 1, numel(y));
    end
     
    xi = ml_util_discretize_binid(x, bs.cm_per_bin_x);
    yi = ml_util_discretize_binid(y, bs.cm_per_bin_y);

    % Locate any points outside the bounds
    badi = find(xi < min(bs.bxi) | xi > max(bs.bxi) | yi < min(bs.byi) | yi > max(bs.byi));
    xi(badi) = nan;
    yi(badi) = nan;

    % Convert to indices in the bins
    xj = xi - min(bs.bxi) + 1;
    yj = yi - min(bs.byi) + 1;
end