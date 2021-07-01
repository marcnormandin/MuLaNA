function mltp_compute_singleunit_placemap_data(obj, session)
    % This will work for any shape.
    
    fl = dir(fullfile(session.getAnalysisDirectory(), '*_singleunit.mat'));
    for iFile = 1:length(fl)
        singleUnitFilename = fullfile(session.getAnalysisDirectory(), fl(iFile).name);
        data = load(singleUnitFilename);
        singleunit = data.singleunit;
        
%         for iTrial = 1:session.getNumTrials()
%             trial = session.getTrial(iTrial);
        for iTrial = 1:session.getNumTrials()
            trial = session.getTrialByOrder(iTrial);
            trialId = trial.getTrialId();
            sliceId = trial.getSliceId();
                
            % Load the data
            spikes = singleunit.sliceSpikes(sliceId);
            tmp = load(fullfile(session.getAnalysisDirectory(), sprintf('slice_%d_movement.mat', sliceId)));
            movement = tmp.movement;
            
            spike_ts_ms = spikes.sliceSpikeTimes_mus(:) / (1.0*10^3);
            
            % Compute the number of bins we need in each dimension
            % The bounds are in cm
%             cm_per_bin = obj.Config.placemaps.cm_per_bin;
%             nbinsx = ceil((movement.boundsX(2) - movement.boundsX(1))/cm_per_bin); 
%             nbinsy = ceil((movement.boundsY(2) - movement.boundsY(1))/cm_per_bin);
            arena = movement.arena;
            if arena.isShape('square')
                x_length_cm = arena.length_cm;
                y_length_cm = x_length_cm;
            elseif arena.isShape('rectangle')
                x_length_cm = arena.x_length_cm;
                y_length_cm = arena.y_length_cm;
            elseif arena.isShape('circle')
                x_length_cm = arena.diameter_cm;
                y_length_cm = x_length_cm;
            else
                error('Unsupported shape (%s). Must be square, rectangle, or circle.', arena.shapeTypeStr);
            end
            
            nbins_rect_x = round(x_length_cm / obj.Config.placemaps.cm_per_bin_rect_both_dim);
            nbins_rect_y = round(y_length_cm / obj.Config.placemaps.cm_per_bin_rect_both_dim);
            cm_per_bin = obj.Config.placemaps.cm_per_bin_rect_both_dim;
            
            mltetrodeplacemap = MLSpikePlacemap(movement.x_cm, movement.y_cm, movement.timestamps_ms, spike_ts_ms, ...
                'speed_cm_per_second', movement.speed_smoothed_cm_per_s, ...
                'boundsx', movement.boundsX, ...
                'boundsy', movement.boundsY, ...
                'nbinsx', nbins_rect_x, ...
                'nbinsy', nbins_rect_y, ...
                'SmoothingProtocol', obj.Config.placemaps.smoothingProtocol, ...
                'smoothingKernel', obj.SmoothingKernelSymmetric, ...
                'criteriaDwellTimeSecondsPerBinMinimum', obj.Config.placemaps.criteria_dwell_time_seconds_per_bin_minimum, ...
                'criteriaSpikesPerBinMinimum', obj.Config.placemaps.criteria_spikes_per_bin_minimum, ...
                'criteriaSpikesPerMapMinimum', obj.Config.placemaps.criteria_spikes_per_map_minimum, ...
                'criteria_speed_cm_per_second_minimum', obj.Config.placemaps.criteria_speed_cm_per_second_minimum, ...
                'criteria_speed_cm_per_second_maximum', obj.Config.placemaps.criteria_speed_cm_per_second_maximum, ...
                'compute_information_rate_pvalue', obj.Config.placemaps.compute_information_rate_pvalue==1);
            
            % Save the data
            outputFolder = fullfile(session.getAnalysisDirectory(), obj.Config.placemaps.outputFolder);
            if ~isfolder(outputFolder)
                mkdir(outputFolder)
            end


            trial_id = trialId;
            slice_id = sliceId;
            trial_use = trial.isEnabled();
            trial_first_dig = trial.getDigs();
            % FixMe!
            trial_context_index = trial.getContextId();
            trial_context_id = trial.getContextId();
            
            % Record this trial with respect to the context
%             contexts = [ti.context]; % all the contexts (which will be processed)
%             ids = [ti.id];
%             trial_context_num = find(ids(contexts == ti(iTrial).context) == ti(iTrial).id);
%             if isempty(trial_context_num)
%                 error('Logic error!');
%             end
            trial_context_num = 0;
            for iTmp = 1:iTrial
                z = session.getTrialByOrder(iTmp);
                if z.getContextId() == trial.getContextId()
                    trial_context_num = trial_context_num + 1;
                end
            end
            
            fnPrefix = split(singleunit.tfileName,'.');
            fnPrefix = fnPrefix{1};
            placemapFilename = fullfile(outputFolder, sprintf('%s_%d_%s', fnPrefix, trialId, obj.Config.placemaps.filenameSuffix));
            fprintf('Saving placemap data to file: %s\n', placemapFilename);
            save(placemapFilename, 'mltetrodeplacemap', 'cm_per_bin', 'trial_id', 'slice_id', 'trial_context_id', 'trial_use', 'trial_first_dig', 'trial_context_index', 'trial_context_num');
        end % trial
    end % for each t-file    
end % function