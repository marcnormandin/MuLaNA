function [cnmfeOptions] = men_cnmfe_options_create(varargin)
    p = inputParser;
    p.CaseSensitive = false;
    
    addParameter(p,'framesPerSecond', 30, @isscalar);
    addParameter(p,'verbose', false, @islogical);    
    
    parse(p, varargin{:});
    
    if p.Results.verbose
        fprintf('Using the following CNMFE settings:\n');
        disp(p.Results)
    end
    
    % -------------------------    COMPUTATION    -------------------------  %
    cnmfeOptions.pars_envs = struct('memory_size_to_use', 12, ...   % GB, memory space you allow to use in MATLAB
        'memory_size_per_patch', 0.6, ...   % GB, space for loading data within one patch
        'patch_dims', [64, 64]); %, ...
        %'batch_frames', 1000);  %GB, patch size
    % -------------------------      SPATIAL      -------------------------  %
    cnmfeOptions.include_residual = false; % If true, look for neurons in the residuals
    cnmfeOptions.gSiz = 15;          % pixel, neuron diameter (default 15)
    cnmfeOptions.gSig = 3; %cnmfeOptions.gSiz / 4.0;           % pixel, gaussian width of a gaussian kernel for filtering the data. 0 means no filtering
    cnmfeOptions.ssub = 1;           % spatial downsampling factor
    cnmfeOptions.with_dendrites = true;   % with dendrites or not
    if cnmfeOptions.with_dendrites
        % determine the search locations by dilating the current neuron shapes
        cnmfeOptions.updateA_search_method = 'dilate'; 
        cnmfeOptions.updateA_bSiz = 5; %20; %5;
        %cnmfeOptions.updateA_dist = neuron.options.dist;
    else
        % determine the search locations by selecting a round area
        cnmfeOptions.updateA_search_method = 'ellipse';
        cnmfeOptions.updateA_dist = 5; %15;
        %cnmfeOptions.updateA_bSiz = neuron.options.dist;
    end
    cnmfeOptions.spatial_constraints = struct('connected', true, 'circular', false);  % you can include following constraints: 'circular'
    cnmfeOptions.spatial_algorithm = 'hals_thresh';

    % -------------------------      TEMPORAL     -------------------------  %
    cnmfeOptions.Fs = p.Results.framesPerSecond;             % frame rate
    cnmfeOptions.tsub = 5;           % temporal downsampling factor
    cnmfeOptions.deconv_flag = true; % Perform deconvolution
    
%     cnmfeOptions.deconv_options = struct('type', 'ar1', ... % model of the calcium traces. {'ar1', 'ar2'}
%         'method', 'constrained', ... % method for running deconvolution {'foopsi', 'constrained', 'thresholded'}
%         'smin', -5, ...         % minimum spike size. When the value is negative, the actual threshold is abs(smin)*noise level
%         'optimize_pars', true, ...  % optimize AR coefficients
%         'optimize_b', true, ...% optimize the baseline);
%         'max_tau', 100);    % maximum decay time (unit: frame);
    
    cnmfeOptions.deconv_options = struct('type', 'ar1', ... % model of the calcium traces. {'ar1', 'ar2'}
        'method', 'constrained', ... % method for running deconvolution {'foopsi', 'constrained', 'thresholded'}
        'smin', -5, ...         % minimum spike size. When the value is negative, the actual threshold is abs(smin)*noise level
        'optimize_pars', true, ...  % optimize AR coefficients
        'optimize_b', true, ... % optimize the baseline);
        'max_tau', 100);
    
    cnmfeOptions.nk = 3;             % detrending the slow fluctuation. usually 1 is fine (no detrending)
    % when changed, try some integers smaller than total_frame/(Fs*30)
    cnmfeOptions.detrend_method = 'spline';  % compute the local minimum as an estimation of trend.

    % -------------------------     BACKGROUND    -------------------------  %
    cnmfeOptions.bg_model = 'ring';  % model of the background {'ring', 'svd'(default), 'nmf'}
    cnmfeOptions.nb = 1; %1.5; % 1;             % number of background sources for each patch (only be used in SVD and NMF model)
    %cnmfeOptions.bg_neuron_factor = 1.5; %added from WIKI documentation
    cnmfeOptions.ring_radius = 18; %round(cnmfeOptions.bg_neuron_factor * cnmfeOptions.gSiz); %100;   % when the ring model used, it is the radius of the ring used in the background model.
    %otherwise, it's just the width of the overlapping area
    cnmfeOptions.num_neighbors = []; % number of neighbors for each neuron

    % -------------------------      MERGING      -------------------------  %
    cnmfeOptions.show_merge = false;  % if true, manually verify the merging step
    cnmfeOptions.merge_thr = 0.65; %0.65    % thresholds for merging neurons; [spatial overlap ratio, temporal correlation of calcium traces, spike correlation]
    cnmfeOptions.method_dist = 'max';   % method for computing neuron distances {'mean', 'max'}
    cnmfeOptions.dmin = 5;       % minimum distances between two neurons. it is used together with merge_thr
    cnmfeOptions.dmin_only = 2;  % merge neurons if their distances are smaller than dmin_only.
    cnmfeOptions.merge_thr_spatial = [0.8, 0.4, -inf];  % merge components with highly correlated spatial shapes (corr=0.8) and small temporal correlations (corr=0.1)

    % -------------------------  INITIALIZATION   -------------------------  %
    cnmfeOptions.K = [];             % maximum number of neurons per patch. when K=[], take as many as possible.
    cnmfeOptions.min_corr = 0.8;     % minimum local correlation for a seeding pixel, default 0.8
    cnmfeOptions.min_pnr = 8; %10; %8;       % minimum peak-to-noise ratio for a seeding pixel
    cnmfeOptions.min_pixel = cnmfeOptions.gSig^2;      % minimum number of nonzero pixels for each neuron
    cnmfeOptions.bd = 0;             % number of rows/columns to be ignored in the boundary (mainly for motion corrected data)
    cnmfeOptions.frame_range = [];   % when [], uses all frames
    cnmfeOptions.save_initialization = false;    % save the initialization procedure as a video.
    cnmfeOptions.use_parallel = false;    % use parallel computation for parallel computing
    cnmfeOptions.show_init = false;   % show initialization results
    cnmfeOptions.choose_params = false; % manually choose parameters
    cnmfeOptions.center_psf = true;  % set the value as true when the background fluctuation is large (usually 1p data)
    % set the value as false when the background fluctuation is small (2p)

    % -------------------------  Residual   -------------------------  %
    cnmfeOptions.min_corr_res = 0.8; % Default 0.7
    cnmfeOptions.min_pnr_res = 8;
    cnmfeOptions.seed_method_res = 'auto';  % method for initializing neurons from the residual
    cnmfeOptions.update_sn = true;

    % ----------------------  WITH MANUAL INTERVENTION  --------------------  %
    cnmfeOptions.with_manual_intervention = false;

end % function
