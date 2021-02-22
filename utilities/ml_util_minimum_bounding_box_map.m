function [qx, qy] = ml_util_minimum_bounding_box_map(r, tx, ty)
    % Now transform the data so the rectangles are axis aligned
    ax = r(2,1) - r(1,1);
    ay = r(2,2) - r(1,2);
    ma = sqrt(ax.^2 + ay.^2);
    ax = ax ./ ma;
    ay = ay ./ ma;
    bx = r(4,1) - r(1,1);
    by = r(4,2) - r(1,2);
    mb = sqrt(bx.^2 + by.^2);
    bx = bx ./ mb;
    by = by ./ mb;

    numP = length(tx);
    qx = zeros(numP,1);
    qy = zeros(numP,1);
    for i = 1:numP
        qx(i) = sum( (tx(i)-r(1,1))*ax + (ty(i)-r(1,2))*ay );
        qy(i) = sum( (tx(i)-r(1,1))*bx + (ty(i)-r(1,2))*by );
    end
end % function
