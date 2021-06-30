function [edgesX] = ml_it_edges_x_uniform_density(x)
    nBinsX = 100;

    x = reshape(x, 1, numel(x));
    nSamples = length(x);
    
    minX = min(x, [], 'all');
    maxX = max(x, [], 'all');
    nSamplesPerBinX = ceil(nSamples ./ nBinsX);
    sx = sort(x);
    edgesX = unique([minX, sx(1:nSamplesPerBinX:end), maxX]);
end