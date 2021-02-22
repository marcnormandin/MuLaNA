function [hsize, hhsize] = ml_util_compute_gaussian_size(smoothingKernelGaussianSize_cm, cmperbin_square)
    hsize = ceil(smoothingKernelGaussianSize_cm / cmperbin_square);
    if mod(hsize,2) ~= 1
        hsize = hsize + 1;
    end
    hhsize = floor((hsize-1)/2);
end