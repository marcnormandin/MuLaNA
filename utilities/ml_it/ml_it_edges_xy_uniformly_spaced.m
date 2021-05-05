function [edgesX, edgesY] = ml_it_edges_xy_uniformly_spaced(x,y)
    x = reshape(x, 1, numel(x));
    y = reshape(y, 1, numel(y));
    pearsonCorr = corrcoef(x', y');
    pearsonCorr = pearsonCorr(1,2);
    
    N = length(x);
    
    nBinXY = round( 1 / sqrt(2) * (1 + sqrt(1 + (24*N/(1-pearsonCorr^2))))^(1/2) );
    edgesX = linspace(min(x), max(x), nBinXY+1);
    edgesY = linspace(min(y), max(y), nBinXY+1);
end