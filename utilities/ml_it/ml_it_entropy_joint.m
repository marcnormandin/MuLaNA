function [entropyXY] = ml_it_entropy_joint(x,y, binMethod)
    if length(x) ~= length(y)
        error('x and y should be the same length.');
    end
    
    if strcmpi(binMethod, 'uniformly_spaced')
        [edgesX, edgesY] = ml_it_edges_xy_uniformly_spaced(x,y);
    elseif strcmpi(binMethod, 'uniform_density')
        [edgesX, edgesY] = ml_it_edges_xy_uniform_density(x,y);
    else
        error('Invalid bin type (%s)', binMethod);
    end

    hc = histcounts2(x, y, edgesX, edgesY);
    probXY = hc ./ sum(hc, 'all');
    entropyXY = 0;
    for i = 1:size(probXY,1)
        for j = 1:size(probXY,2)
            p = probXY(i,j);
            if p ~= 0
                entropyXY = entropyXY + p * log2(1/p);
            end
        end
    end
end % function