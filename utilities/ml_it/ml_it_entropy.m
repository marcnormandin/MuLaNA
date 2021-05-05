function [entropyX] = ml_it_entropy(x, binMethod)
    if strcmpi(binMethod, 'uniformly_spaced')
        edges = ml_it_edges_x_uniformly_spaced(x);
    elseif strcmpi(binMethod, 'uniform_density')
        edges = ml_it_edges_x_uniform_density(x);
    else
        error('Invalid bin type (%s)', binMethod);
    end
    
    hc = histcounts(x, edges);
    probX = hc ./ sum(hc, 'all');
    
    entropyX = 0;
    for i = 1:length(probX)
       p = probX(i);
       if p ~= 0
           entropyX = entropyX + p * log2(1./p);
       end
    end
end % function