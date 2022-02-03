function [Z] = ml_bs_accumulate_xy(bs, x, y, v)
    % This function discretizes the position values using the bin system
    % and then accumulates the associated value into the respective
    % locations. If v is nan, it will not be added.
    if isempty(x) && isempty(y)
        Z = zeros(size(bs.XX));
        return
    end
    
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
    
    
    
    % Must be a vector of the same length as x and y or single-valued.
    if length(v) ~= length(x) && length(v) ~= 1
        error('v must be an array of the same length of x and y, or a single value.');
    end
    
    [xj, yj] = ml_bs_discretize_xy(bs, x, y);
    Z = zeros(bs.ny, bs.nx);
    nPoints = length(xj);
    for k = 1:nPoints
        if ~isnan(xj(k)) && ~isnan(yj(k))
            vPrev = Z(yj(k), xj(k)); % prev count
        
            if length(v) == 1
                vNew = vPrev + v; % increment
            else
                vNew = vPrev + v(k); % v is a vector
            end
            
            if ~isnan(vNew)
                Z(yj(k), xj(k)) = vNew;
            end
        end
    end
    
end