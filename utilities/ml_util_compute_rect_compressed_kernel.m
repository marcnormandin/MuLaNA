function [mySquareKernel] = ml_util_compute_rect_compressed_kernel(arenaLengthRatio, smoothingKernelGaussianSize_cm, sigma_cm, cmperbin_square_smallest)
    % This compute an asymmetric gaussian kernel used for the compressed
    % rectangle
    % arenaLengthRatio is length_x / length_y in physical lengths. eg. 20 / 30.
    
    [~, hhsizex] = ml_util_compute_gaussian_size(smoothingKernelGaussianSize_cm, cmperbin_square_smallest);
    [~, hhsizey] = ml_util_compute_gaussian_size(smoothingKernelGaussianSize_cm, cmperbin_square_smallest);
    x = -hhsizex:hhsizex;
    y = -hhsizey:hhsizey;
    [xx,yy] = meshgrid(x, y);
    

    % Square sigmas (asymmetrc)
    s1 = sigma_cm / cmperbin_square_smallest;
    s2 = sigma_cm / cmperbin_square_smallest * arenaLengthRatio;

    mySquareKernel = ml_util_bivariatepdf(s1,s2,0,0,0,xx,yy);
    
    % Normalize
    mySquareKernel = mySquareKernel ./ max(mySquareKernel, [], 'all');
end