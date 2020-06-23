function [traceFilt, spikes, deconv_options] = ml_cai_deconvolve_cnmfe_raw_trace(deconv_options, traceRaw)
    % traceRaw is supposed to be a single "RawTraces" from cnmfe.
    
    % These were parameters that fit the data well for both
    % the GCamp6f transfected mouse, and the transgenic mouse.
%     deconv_options_0.max_tau = framesPerSecond;
%     deconv_options_0.method = 'constrained';
%     deconv_options_0.type = 'ar1';
%     deconv_options_0.sn = 0.05; 
%     deconv_options_0.tau_range = [1 100]*framesPerSecond;

    [traceFilt, spikes, deconv_options]= deconvolveCa(traceRaw, deconv_options); %, 'maxIter', deconv_options.maxIterations);
end
