function [r] = ml_alg_smallest_enclosing_rectangle(tx, ty)
    % This code computes the smallest rectangle that encloses the points
    % given by tx and ty. NOTE! It will enclose all of the points so filter
    % out those that are due to noise if needed. It was written for the
    % auto placemap spike code that does everything automatically.
    %
    % Returns the corners with size(r) = (4,2). e.g. corner 1 r(1,1) = x
    % r(1,2) = y.
    
    % Compute the points in tx,ty that belong to the convex hull.
    k = convhull(tx, ty);

    % Find the minimum rectangle
    % For every pair of points, compute the min and max in each dimension
    % after projecting
    numK = length(k);
    numP = length(tx);
    kx = tx(k);
    ky = ty(k);
    A = cell(numK-1,9);
    for k = 1:numK-1
        ux = kx(k+1) - kx(k);
        uy = ky(k+1) - ky(k);
        mu = sqrt(ux.^2 + uy.^2);
        ux = ux ./ mu; % make unit vector
        uy = uy ./ mu;
        vx = -uy;
        vy = ux;

        px = [];
        py = [];
        for i = 1:numP
            px(end+1) = sum((tx(i)-kx(k)) * ux + (ty(i)-ky(k))*uy);
            py(end+1) = sum((tx(i)-kx(k)) * vx + (ty(i)-ky(k))*vy);
        end

        A{k,1} = (max(px)-min(px)) * (max(py)-min(py));
        A{k,2} = min(px);
        A{k,3} = max(px);
        A{k,4} = min(py);
        A{k,5} = max(py);
        A{k,6} = ux;
        A{k,7} = uy;
        A{k,8} = vx;
        A{k,9} = vy;
    end
    [minA, j] = min([A{:,1}]);
    r = zeros(4,2);

    % These are the 4 corners of the best fit rectangle in (x,y) pairs
    r(1,:) = [kx(j) + A{j,6}*A{j,2}, ky(j) + A{j,7}*A{j,2}];
    r(2,:) = [kx(j) + A{j,6}*A{j,3}, ky(j) + A{j,7}*A{j,3}];
    r(4,:) = [r(1,1) + A{j,8}*A{j,5}, r(1,2) + A{j,9}*A{j,5}];
    r(3,:) = [r(2,1) + A{j,8}*A{j,5}, r(2,2) + A{j,9}*A{j,5}];
end % function
        