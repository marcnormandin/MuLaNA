function mltp_compute_singleunit_placemap_data_rect(obj, session)
    if obj.config.use_d1_xlsx == 1
        d1xlsxFilename = fullfile(session.rawFolder, 'd1.xlsx');
        fprintf('Reading %s ... ', d1xlsxFilename);
        [~,~,d1xlsx] = xlsread(d1xlsxFilename);
        fprintf('done!\n');
    end

    % Form the grid
    boundsx = obj.config.placemaps_rect.bounds_x;
    boundsy = obj.config.placemaps_rect.bounds_y;
    nbinsx = obj.config.placemaps_rect.nbins_x;
    nbinsy = obj.config.placemaps_rect.nbins_y;

    fl = dir(fullfile(session.analysisFolder, '*_singleunit_canon_rect.mat'));
    for iFile = 1:length(fl)
        singleUnitFilename = fullfile(session.analysisFolder, fl(iFile).name);
        data = load(singleUnitFilename);
        singleunit = data.singleunit;

        for iTrial = 1:session.num_trials_recorded
            % Load the data
            spikes = singleunit.trialSpikes(iTrial);
            data = load(fullfile(session.analysisFolder, sprintf('trial_%d_canon_rect.mat', iTrial)));
            canon = data.canon;
            x = canon.pos.x;
            y = canon.pos.y;
            si = spikes.indices;
            ts_ms = canon.timeStamps_mus(:) ./ (1.0*10^3); 
            spe = canon.spe;

            %mltetrodeplacemap = MLTetrodePlacemap(x, y, ts_ms, si, boundsx, boundsy, nbinsx, nbinsy, ...
            %    obj.config.placemaps_rect.kernel_gaussian_size_bins, obj.config.placemaps_rect.kernel_gaussian_sigma_cm);
            mltetrodeplacemap = MLSpikePlacemap(x, y, ts_ms, si, ...
                'speed_cm_per_second', spe, ...
                'boundsx', boundsx, ...
                'boundsy', boundsy, ...
                'nbinsx', nbinsx, ...
                'nbinsy', nbinsy, ...
                'SmoothingProtocol', obj.config.placemaps.smoothingProtocol, ...
                'smoothingKernel', obj.smoothingKernelRect, ...
                'criteriaDwellTimeSecondsPerBinMinimum', obj.config.placemaps.criteria_dwell_time_seconds_per_bin_minimum, ...
                'criteriaSpikesPerBinMinimum', obj.config.placemaps.criteria_spikes_per_bin_minimum, ...
                'criteria_speed_cm_per_second_minimum', obj.config.placemaps.criteria_speed_cm_per_second_minimum, ...
                'criteria_speed_cm_per_second_maximum', obj.config.placemaps.criteria_speed_cm_per_second_maximum);
            
            % Save the data
            outputFolder = fullfile(session.analysisFolder, obj.config.canon_rect_placemaps_folder);
            if ~isfolder(outputFolder)
                mkdir(outputFolder)
            end

            %
            % Record the context in the mat file
            trial_num = iTrial;
            context_trial_num = []; % The trial number within the context
            context_index = [];
            for iContext = 1:session.num_contexts
                context_index = iContext;
                context_trial_num = find(session.context_trial_ids{iContext} == trial_num);
                if isempty(context_trial_num)
                    continue
                else
                    break
                end
            end

            trial_context_index = context_index;
            trial_context_num = context_trial_num;

            trial_context_id = session.record.trial_info.contexts(iTrial);
            trial_use = session.record.trial_info.use(iTrial) == 1; 
            trial_first_dig = session.record.trial_info.digs(iTrial);

            fnPrefix = split(singleunit.tfileName,'.');
            fnPrefix = fnPrefix{1};
            placemapFilename = fullfile(outputFolder, sprintf('%s_%d_mltetrodeplacemaprect.mat', fnPrefix, iTrial));
            fprintf('Saving placemap data to file: %s\n', placemapFilename);
            save(placemapFilename, 'mltetrodeplacemap', 'trial_num', 'trial_context_id', 'trial_use', 'trial_first_dig', 'trial_context_index', 'trial_context_num');
        end % trial



    end % for each t-file    
end % function