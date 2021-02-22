function [r] = ml_util_minimum_bounding_box(tx, ty)
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
    r(1,:) = [kx(j) + A{j,6}*A{j,2}, ky(j) + A{j,7}*A{j,2}];
    r(2,:) = [kx(j) + A{j,6}*A{j,3}, ky(j) + A{j,7}*A{j,3}];
    r(4,:) = [r(1,1) + A{j,8}*A{j,5}, r(1,2) + A{j,9}*A{j,5}];
    r(3,:) = [r(2,1) + A{j,8}*A{j,5}, r(2,2) + A{j,9}*A{j,5}];
    
    % Make the first point the one with the lowest y-value by circularly
    % shifting so that the order of the points is the same
    [~,i] = min(r(:,2));
    r = circshift(r,1-i);
end % function
