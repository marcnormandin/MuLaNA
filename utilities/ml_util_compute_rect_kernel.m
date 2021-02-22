function smoothingKernel = ml_util_compute_rect_kernel(smoothingKernelGaussianSize_cm, smoothingKernelGaussianSigma_cm, cm_per_bin)
    [hsize, ~] = ml_util_compute_gaussian_size(smoothingKernelGaussianSize_cm, cm_per_bin);
    smoothingKernel = fspecial('gaussian', hsize, smoothingKernelGaussianSigma_cm / cm_per_bin);
    smoothingKernel = smoothingKernel ./ sum(smoothingKernel(:), 'all'); % Isabel wants this like the other
end