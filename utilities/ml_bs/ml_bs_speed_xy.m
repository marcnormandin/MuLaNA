function [smapMean, smapStd] = ml_bs_speed_xy(bs, x, y, speed)
    % This function discretizes the position values using the bin system.
    
    nel = length(x);
    if length(y) ~= nel || length(speed) ~= nel
        error('Invalid lengths. All must be the same.');
    end
    
    %[trans, xj, yj] = ml_bs_transitions_xy(bs, x, y);
    [xj, yj] = ml_bs_discretize_xy(bs, x, y);
    
    smapMean = nan(bs.ny, bs.nx);
    smapStd = nan(bs.ny, bs.nx);
    u = unique([xj; yj]', 'rows');
    for k = 1:length(u)
       xk = u(k,1);
       yk = u(k,2);

       imatch = intersect(find(xj == xk), find(yj == yk));
       
       ms = mean(speed(imatch), 'all', 'omitnan');
       smapMean(yk, xk) = ms;
       
       ss = std(speed(imatch), 0, 'all', 'omitnan');
       smapStd(yk, xk) = ss;
    end
end