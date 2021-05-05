function [edgesX] = ml_it_edges_x_uniformly_spaced(x)
    N = length(x);
    zi = (8+324*N+12*sqrt(36*N + 729*N^2))^(1/3);
    nBinX = round( zi/6 + 2 / (3*zi) + 1/3 );

    edgesX = linspace(min(x), max(x), nBinX+1);
end