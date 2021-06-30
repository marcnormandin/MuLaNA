function binSystem = ml_bs_create(boundsx, boundsy, cm_per_bin_x, cm_per_bin_y)
    % This is the first function of the bin system that should be called to
    % make the structure that the other code requires. It will discretize
    % the xy plane using a given bin size for each dimension.
    
    bxi = ml_util_discretize_binid(boundsx, cm_per_bin_x);
    byi = ml_util_discretize_binid(boundsy, cm_per_bin_y);
    nx = max(bxi) - min(bxi) + 1; % total number of discrete groups
    ny = max(byi) - min(byi) + 1; % total number of discrete groups
    [XX,YY] = meshgrid(min(boundsx):cm_per_bin_x:max(boundsx), min(boundsy):cm_per_bin_y:max(boundsy));

    binSystem.bxi = bxi;
    binSystem.byi = byi;
    binSystem.nx = nx;
    binSystem.ny = ny;
    binSystem.XX = XX;
    binSystem.YY = YY;
    binSystem.boundsx = boundsx;
    binSystem.boundsy = boundsy;
    binSystem.cm_per_bin_x = cm_per_bin_x;
    binSystem.cm_per_bin_y = cm_per_bin_y;
end