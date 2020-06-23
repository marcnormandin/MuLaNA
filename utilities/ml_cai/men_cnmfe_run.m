function [ms] = men_cnmfe_run( cnmfeOptions, alignedScopeFilename )
    %% choose data
    neuron = Sources2D();
    nam = neuron.select_data( alignedScopeFilename );  %if nam is [], then select data interactively

    if cnmfeOptions.with_dendrites
        % determine the search locations by dilating the current neuron shapes
        cnmfeOptions.updateA_dist = neuron.options.dist;
    else
        % determine the search locations by selecting a round area
        cnmfeOptions.updateA_bSiz = neuron.options.dist;
    end

    % -------------------------    UPDATE ALL    -------------------------  %
    neuron.updateParams('gSig', cnmfeOptions.gSig, ...       % -------- spatial --------
        'gSiz', cnmfeOptions.gSiz, ...
        'ring_radius', cnmfeOptions.ring_radius, ...
        'ssub', cnmfeOptions.ssub, ...
        'search_method', cnmfeOptions.updateA_search_method, ...
        'bSiz', cnmfeOptions.updateA_bSiz, ...
        'dist', cnmfeOptions.updateA_bSiz, ...
        'spatial_constraints', cnmfeOptions.spatial_constraints, ...
        'spatial_algorithm', cnmfeOptions.spatial_algorithm, ...
        'tsub', cnmfeOptions.tsub, ...                       % -------- temporal --------
        'deconv_flag', cnmfeOptions.deconv_flag, 'deconv_options', cnmfeOptions.deconv_options, ...
        'nk', cnmfeOptions.nk, ...
        'detrend_method', cnmfeOptions.detrend_method, ...
        'background_model', cnmfeOptions.bg_model, ...       % -------- background --------
        'nb', cnmfeOptions.nb, ...
        'ring_radius', cnmfeOptions.ring_radius, ...
        'num_neighbors', cnmfeOptions.num_neighbors, ...
        'merge_thr', cnmfeOptions.merge_thr, ...             % -------- merging ---------
        'dmin', cnmfeOptions.dmin, ...
        'method_dist', cnmfeOptions.method_dist, ...
        'min_corr', cnmfeOptions.min_corr, ...               % ----- initialization -----
        'min_pnr', cnmfeOptions.min_pnr, ...
        'min_pixel', cnmfeOptions.min_pixel, ...
        'bd', cnmfeOptions.bd, ...
        'center_psf', cnmfeOptions.center_psf);
    neuron.Fs = cnmfeOptions.Fs;

    %% distribute data and be ready to run source extraction
    neuron.getReady(cnmfeOptions.pars_envs);

    %% initialize neurons from the video data within a selected temporal range
    if cnmfeOptions.choose_params
        % change parameters for optimized initialization
        [cnmfeOptions.gSig, cnmfeOptions.gSiz, cnmfeOptions.ring_radius, cnmfeOptions.min_corr, cnmfeOptions.min_pnr] = neuron.set_parameters();
    end

    [center, Cn, PNR] = neuron.initComponents_parallel(cnmfeOptions.K, cnmfeOptions.frame_range, cnmfeOptions.save_initialization, cnmfeOptions.use_parallel);
    neuron.compactSpatial();
    if cnmfeOptions.show_init
        figure();
        ax_init= axes();
        imagesc(Cn, [0, 1]); colormap gray;
        hold on;
        plot(center(:, 2), center(:, 1), '.r', 'markersize', 10);
        drawnow

        figure;
        imagesc(PNR);
        drawnow
    end

    %% estimate the background components
    neuron.update_background_parallel(cnmfeOptions.use_parallel);
    neuron_init = neuron.copy();

    %%  merge neurons and update spatial/temporal components
    neuron.merge_neurons_dist_corr(cnmfeOptions.show_merge);
    neuron.merge_high_corr(cnmfeOptions.show_merge, cnmfeOptions.merge_thr_spatial);

    %% update spatial components

    %% pick neurons from the residual
    if cnmfeOptions.include_residual
        [center_res, Cn_res, PNR_res] = neuron.initComponents_residual_parallel([], cnmfeOptions.save_initialization, cnmfeOptions.use_parallel, cnmfeOptions.min_corr_res, cnmfeOptions.min_pnr_res, cnmfeOptions.seed_method_res);
        if cnmfeOptions.show_init
            figure
            imagesc(Cn_res, [0, 1]); colormap gray; hold on;
            plot(center_res(:, 2), center_res(:, 1), '.g', 'markersize', 10);
            drawnow

            figure;
            imagesc(PNR_res);
            drawnow
        end
        neuron_init_res = neuron.copy();
    end

    %% udpate spatial&temporal components, delete false positives and merge neurons
    % update spatial
    if cnmfeOptions.update_sn
        neuron.update_spatial_parallel(cnmfeOptions.use_parallel, true);
        cnmfeOptions.update_sn = false;
    else
        neuron.update_spatial_parallel(cnmfeOptions.use_parallel);
    end
    % merge neurons based on correlations
    neuron.merge_high_corr(cnmfeOptions.show_merge, cnmfeOptions.merge_thr_spatial);

    for m=1:2
        % update temporal
        neuron.update_temporal_parallel(cnmfeOptions.use_parallel);

        % delete bad neurons
        neuron.remove_false_positives();

        % merge neurons based on temporal correlation + distances
        neuron.merge_neurons_dist_corr(cnmfeOptions.show_merge);
    end

    %% add a manual intervention and run the whole procedure for a second time
    neuron.options.spatial_algorithm = 'nnls';
    if cnmfeOptions.with_manual_intervention
        cnmfeOptions.show_merge = true;
        neuron.orderROIs('snr');   % order neurons in different ways {'snr', 'decay_time', 'mean', 'circularity'}
        neuron.viewNeurons([], neuron.C_raw);

        % merge closeby neurons
        neuron.merge_close_neighbors(true, cnmfeOptions.dmin_only);

        % delete neurons
        tags = neuron.tag_neurons_parallel();  % find neurons with fewer nonzero pixels than min_pixel and silent calcium transients
        ids = find(tags>0);
        if ~isempty(ids)
            neuron.viewNeurons(ids, neuron.C_raw);
        end
    end
    %% run more iterations
    neuron.update_background_parallel(cnmfeOptions.use_parallel);
    neuron.update_spatial_parallel(cnmfeOptions.use_parallel);
    neuron.update_temporal_parallel(cnmfeOptions.use_parallel);

    K = size(neuron.A,2);
    tags = neuron.tag_neurons_parallel();  % find neurons with fewer nonzero pixels than min_pixel and silent calcium transients
    neuron.remove_false_positives();
    neuron.merge_neurons_dist_corr(cnmfeOptions.show_merge);
    neuron.merge_high_corr(cnmfeOptions.show_merge, cnmfeOptions.merge_thr_spatial);

    if K~=size(neuron.A,2)
        neuron.update_spatial_parallel(cnmfeOptions.use_parallel);
        neuron.update_temporal_parallel(cnmfeOptions.use_parallel);
        neuron.remove_false_positives();
    end

    %% save the workspace for future analysis
    neuron.orderROIs('snr');
    %cnmfe_path = neuron.save_workspace();

    %% show neuron contours
    ms.Options = neuron.options;
    ms.Centroids = center;
    ms.CorrProj = Cn;
    ms.PeakToNoiseProj = PNR;

    if cnmfeOptions.include_residual
        ms.CentroidsRes = center_res;
        ms.CorrProjRes = Cn_res;
        ms.PeakToNoiseProjRes = PNR_res;
    end

    ms.FiltTraces = neuron.C';
    ms.RawTraces = neuron.C_raw';
    ms.SFPs = neuron.reshape(neuron.A, 2);
    ms.numNeurons = size(ms.SFPs,3);
    ms.neuron = neuron;
    ms.cnmfeOptions = cnmfeOptions;

end % function
