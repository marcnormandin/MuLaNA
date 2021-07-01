function mltp_compute_singleunit_placemap_data_shrunk(obj, session)
    % This shrinks from a rectangle to a square in so that the 90 degree
    % rotations can be performed for the pixel-to-pixel correlations.
    if ~strcmpi(obj.Experiment.getArenaGeometry().shape, 'rectangle')
        fprintf('No need to shrink since shape is not a rectangle.\n');
        return;
    end
    
    fl = dir(fullfile(session.getAnalysisDirectory(), '*_singleunit.mat'));
    for iFile = 1:length(fl)
        singleUnitFilename = fullfile(session.getAnalysisDirectory(), fl(iFile).name);
        data = load(singleUnitFilename);
        singleunit = data.singleunit;
        
        for iTrial = 1:session.getNumTrials()
            trial = session.getTrialByOrder(iTrial);
            trialId = trial.getTrialId();
            sliceId = trial.getSliceId();
                
            % Load the data
            spikes = singleunit.sliceSpikes(sliceId);
            tmp = load(fullfile(session.getAnalysisDirectory(), sprintf('slice_%d_movement.mat', sliceId)));
            movement = tmp.movement;
            
            spike_ts_ms = spikes.sliceSpikeTimes_mus(:) / (1.0*10^3);
            
            % WE NEED TO TRANSFORM THE DATA FROM A RECTANGLE TO A SQUARE
            trueArena = movement.arena;
            arenaLength_smallest = min([trueArena.x_length_cm, trueArena.y_length_cm]);
            cm_per_bin = obj.Config.placemaps.cm_per_bin_square_smallest_dim;
            shrunk_length_cm = arenaLength_smallest; %trueArena.x_length_cm; % should be the smallest dimension (width or x_length_cm)
            shrunkArena = MLArenaSquare(...
                movement.arena.getReferencePointsVideo(), ...
                shrunk_length_cm);
            
            % Transform positions from video to canonical (pixels to cm, but will be distorted)
            [x_shrunk_cm, y_shrunk_cm] = shrunkArena.tranformVidToCanonPoints(movement.x_px, movement.y_px);
        
            [boundsX, boundsY] = shrunkArena.getCanonicalBounds();
            
            % Compute the number of bins we need in each dimension
            % The bounds are in cm
            %cm_per_bin = obj.Config.placemaps.cm_per_bin;
            %nbinsx = ceil((boundsX(2) - boundsX(1))/cm_per_bin); 
            %nbinsy = ceil((boundsY(2) - boundsY(1))/cm_per_bin);
            
            nbins_square = round(arenaLength_smallest / obj.Config.placemaps.cm_per_bin_square_smallest_dim);

            % The speed should come from whatever the true shape is
            mltetrodeplacemap = MLSpikePlacemap(x_shrunk_cm, y_shrunk_cm, movement.timestamps_ms, spike_ts_ms, ...
                'speed_cm_per_second', movement.speed_smoothed_cm_per_s, ...
                'boundsx', boundsX, ...
                'boundsy', boundsY, ...
                'nbinsx', nbins_square, ...
                'nbinsy', nbins_square, ...
                'SmoothingProtocol', obj.Config.placemaps.smoothingProtocol, ...
                'smoothingKernel', obj.SmoothingKernelRectCompressed, ...
                'criteriaDwellTimeSecondsPerBinMinimum', obj.Config.placemaps.criteria_dwell_time_seconds_per_bin_minimum, ...
                'criteriaSpikesPerBinMinimum', obj.Config.placemaps.criteria_spikes_per_bin_minimum, ...
                'criteriaSpikesPerMapMinimum', obj.Config.placemaps.criteria_spikes_per_map_minimum, ...
                'criteria_speed_cm_per_second_minimum', obj.Config.placemaps.criteria_speed_cm_per_second_minimum, ...
                'criteria_speed_cm_per_second_maximum', obj.Config.placemaps.criteria_speed_cm_per_second_maximum, ...
                'compute_information_rate_pvalue', false);

            
            % Save the data
            outputFolder = fullfile(session.getAnalysisDirectory(), obj.Config.placemaps.outputFolderShrunk);
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
