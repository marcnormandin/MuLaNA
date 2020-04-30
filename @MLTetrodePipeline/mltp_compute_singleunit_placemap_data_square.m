function mltp_compute_singleunit_placemap_data_square(obj, session)              
    % Form the grid
    boundsx = obj.config.placemaps_square.bounds_x;
    boundsy = obj.config.placemaps_square.bounds_y;
    nbinsx = obj.config.placemaps_square.nbins_x;
    nbinsy = obj.config.placemaps_square.nbins_y;

    fl = dir(fullfile(session.analysisFolder, '*_singleunit_canon_square.mat'));
    for iFile = 1:length(fl)
        singleUnitFilename = fullfile(session.analysisFolder, fl(iFile).name);
        data = load(singleUnitFilename);
        singleunit = data.singleunit;

        sr = session.sessionRecord;
        ti = sr.getTrialsToProcess();
        for iTrial = 1:sr.getNumTrialsToProcess()
            trialId = ti(iTrial).id;
            
            % Load the data
            spikes = singleunit.trialSpikes(trialId);
            data = load(fullfile(session.analysisFolder, sprintf('trial_%d_canon_square.mat', trialId)));
            canon = data.canon;
            x = canon.pos.x;
            y = canon.pos.y;
%             si = spikes.indices;
%             sx = spikes.x;
%             sy = spikes.y;
%             ss = spikes.spe;
            spike_ts_ms = spikes.trialSpikeTimes_mus(:) / (1.0*10^3);
            
            ts_ms = canon.timeStamps_mus(:) / (1.0*10^3); 

            %mltetrodeplacemap = MLTetrodePlacemap(x, y, ts_ms, si, boundsx, boundsy, nbinsx, nbinsy, ...
            %    obj.config.placemaps_rect.kernel_gaussian_size_bins, obj.config.placemaps_rect.kernel_gaussian_sigma_cm);

            % FixMe! We need the true velocity, but should probably get it
            % another way. This could be improved. It gets the speed from
            % the rectangle mapping.
            data2 = load(fullfile(session.analysisFolder, sprintf('trial_%d_canon_rect.mat', trialId)));
            spe = data2.canon.spe;
            
            mltetrodeplacemap = MLSpikePlacemap(x, y, ts_ms, spike_ts_ms, ...
                'speed_cm_per_second', spe, ...
                'boundsx', boundsx, ...
                'boundsy', boundsy, ...
                'nbinsx', nbinsx, ...
                'nbinsy', nbinsy, ...
                'SmoothingProtocol', obj.config.placemaps.smoothingProtocol, ...
                'smoothingKernel', obj.smoothingKernelSquare, ...
                'criteriaDwellTimeSecondsPerBinMinimum', obj.config.placemaps.criteria_dwell_time_seconds_per_bin_minimum, ...
                'criteriaSpikesPerBinMinimum', obj.config.placemaps.criteria_spikes_per_bin_minimum, ...
                'criteriaSpikesPerMapMinimum', obj.config.placemaps.criteria_spikes_per_map_minimum, ...
                'criteria_speed_cm_per_second_minimum', obj.config.placemaps.criteria_speed_cm_per_second_minimum, ...
                'criteria_speed_cm_per_second_maximum', obj.config.placemaps.criteria_speed_cm_per_second_maximum);
            
            % Save the data
            outputFolder = fullfile(session.analysisFolder, obj.config.canon_square_placemaps_folder);
            if ~isfolder(outputFolder)
                mkdir(outputFolder)
            end

            % Record the context in the mat file
%             trial_num = ti(trialId).sequenceNum;
            
%             context_trial_num = []; % The trial number within the context
%             context_index = [];
%             for iContext = 1:session.num_contexts
%                 context_index = iContext;
%                 context_trial_num = find(session.context_trial_ids{iContext} == trial_num);
%                 if isempty(context_trial_num)
%                     continue
%                 else
%                     break
%                 end
%             end
% 
%             trial_context_index = context_index;
%             trial_context_num = context_trial_num;
% 
%             trial_context_id = session.record.trial_info.contexts(trialId);
%             trial_use = session.record.trial_info.use(trialId) == 1; 
%             trial_first_dig = session.record.trial_info.digs(trialId);

            trial_num = ti(trialId).sequenceNum;
            trial_use = ti(trialId).use;
            trial_first_dig = ti(trialId).digs;
            % FixMe!
            trial_context_index = ti(trialId).context;
            trial_context_id = ti(trialId).context;
            
            % Record this trial with respect to the context
            contexts = [ti.context]; % all the contexts (which will be processes)
            ids = [ti.id];
            trial_context_num = find(ids(contexts == ti(trialId).context) == ti(trialId).id);
            if isempty(trial_context_num)
                error('Logic error!');
            end
             

            fnPrefix = split(singleunit.tfileName,'.');
            fnPrefix = fnPrefix{1};
            placemapFilename = fullfile(outputFolder, sprintf('%s_%d_mltetrodeplacemapsquare.mat', fnPrefix, trialId));
            fprintf('Saving placemap data to file: %s\n', placemapFilename);
            save(placemapFilename, 'mltetrodeplacemap', 'trial_num', 'trial_context_id', 'trial_use', 'trial_first_dig', 'trial_context_index', 'trial_context_num');
        end % trial
    end % for each t-file    
end % function