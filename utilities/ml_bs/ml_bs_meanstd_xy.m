function [mapMean, mapStd] = ml_bs_meanstd_xy(bs, x, y, v)    
    if size(x,1) ~= 1 && size(x,2) ~= 1
        error('Invalid size of x. Should be 1xN.');
    end
    
    if size(y,1) ~= 1 && size(y,2) ~= 1
        error('Invalid size of y. Should be 1xN');
    end
    
    if size(v,1) ~= 1 && size(v,2) ~= 1
        error('Invalid size of v. Should be 1xN');
    end
    
    if size(x,1) ~= 1
        x = reshape(x, 1, numel(x));
    end
    
    if size(y,1) ~= 1
        y = reshape(y, 1, numel(y));
    end
    
    if size(v,1) ~= 1
        v = reshape(v, 1, numel(v));
    end
    
    nel = length(x);
    if length(y) ~= nel || length(v) ~= nel
        error('Invalid lengths. All must be the same.');
    end
    
    [xj, yj] = ml_bs_discretize_xy(bs, x, y);
    
    mapMean = nan(bs.ny, bs.nx);
    mapStd = nan(bs.ny, bs.nx);
    u = unique([xj; yj]', 'rows');
    iubad = [];
    for k = 1:length(u)
       if ~isfinite(u(k,1)) || ~isfinite(u(k,2))
           iubad(end+1) = k;
       end
    end
    u(iubad,:) = [];
    
    for k = 1:length(u)
       xk = u(k,1);
       yk = u(k,2);

       imatch = intersect(find(xj == xk), find(yj == yk));
       
       ms = mean(v(imatch), 'all', 'omitnan');
       mapMean(yk, xk) = ms;
       
       ss = std(v(imatch), 0, 'all', 'omitnan');
       mapStd(yk, xk) = ss;
    end
end
