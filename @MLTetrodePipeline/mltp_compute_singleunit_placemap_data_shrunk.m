function mltp_compute_singleunit_placemap_data_shrunk(obj, session)
    % This shrinks from a rectangle to a square in so that the 90 degree
    % rotations can be performed for the pixel-to-pixel correlations.
    if ~strcmpi(obj.getArena().shape, 'rectangle')
        fprintf('No need to shrink since shape is not a rectangle.\n');
        return;
    end
    
    fl = dir(fullfile(session.analysisFolder, '*_singleunit.mat'));
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
            tmp = load(fullfile(session.analysisFolder, sprintf('trial_%d_movement.mat', trialId)));
            movement = tmp.movement;
            
            spike_ts_ms = spikes.trialSpikeTimes_mus(:) / (1.0*10^3);
            
            % WE NEED TO TRANSFORM THE DATA FROM A RECTANGLE TO A SQUARE
            trueArena = movement.arena;
            shrunk_length_cm = trueArena.x_length_cm; % should be the smallest dimension (width or x_length_cm)
            shrunkArena = MLArenaSquare(...
                movement.arena.getReferencePointsVideo(), ...
                shrunk_length_cm);
            
            % Transform positions from video to canonical (pixels to cm, but will be distorted)
            [x_shrunk_cm, y_shrunk_cm] = shrunkArena.tranformVidToCanonPoints(movement.x_px, movement.y_px);
        
            [boundsX, boundsY] = shrunkArena.getCanonicalBounds();
            
            % Compute the number of bins we need in each dimension
            % The bounds are in cm
            cm_per_bin = obj.config.placemaps.cm_per_bin;
            nbinsx = ceil((boundsX(2) - boundsX(1))/cm_per_bin); 
            nbinsy = ceil((boundsY(2) - boundsY(1))/cm_per_bin);

            % The speed should come from whatever the true shape is
            mltetrodeplacemap = MLSpikePlacemap(x_shrunk_cm, y_shrunk_cm, movement.timestamps_ms, spike_ts_ms, ...
                'speed_cm_per_second', movement.speed_smoothed_cm_per_s, ...
                'boundsx', boundsX, ...
                'boundsy', boundsY, ...
                'nbinsx', nbinsx, ...
                'nbinsy', nbinsy, ...
                'SmoothingProtocol', obj.config.placemaps.smoothingProtocol, ...
                'smoothingKernel', obj.smoothingKernel, ...
                'criteriaDwellTimeSecondsPerBinMinimum', obj.config.placemaps.criteria_dwell_time_seconds_per_bin_minimum, ...
                'criteriaSpikesPerBinMinimum', obj.config.placemaps.criteria_spikes_per_bin_minimum, ...
                'criteriaSpikesPerMapMinimum', obj.config.placemaps.criteria_spikes_per_map_minimum, ...
                'criteria_speed_cm_per_second_minimum', obj.config.placemaps.criteria_speed_cm_per_second_minimum, ...
                'criteria_speed_cm_per_second_maximum', obj.config.placemaps.criteria_speed_cm_per_second_maximum);
            
            % Save the data
            outputFolder = fullfile(session.analysisFolder, obj.config.placemaps.outputFolderShrunk);
            if ~isfolder(outputFolder)
                mkdir(outputFolder)
            end


            trial_num = ti(iTrial).sequenceNum;
            trial_use = ti(iTrial).use;
            trial_first_dig = ti(iTrial).digs;
            % FixMe!
            trial_context_index = ti(iTrial).context;
            trial_context_id = ti(iTrial).context;
            
            % Record this trial with respect to the context
            contexts = [ti.context]; % all the contexts (which will be processes)
            ids = [ti.id];
            trial_context_num = find(ids(contexts == ti(iTrial).context) == ti(iTrial).id);
            if isempty(trial_context_num)
                error('Logic error!');
            end

            fnPrefix = split(singleunit.tfileName,'.');
            fnPrefix = fnPrefix{1};
            placemapFilename = fullfile(outputFolder, sprintf('%s_%d_%s', fnPrefix, trialId, obj.config.placemaps.filenameSuffix));
            fprintf('Saving placemap data to file: %s\n', placemapFilename);
            save(placemapFilename, 'mltetrodeplacemap', 'cm_per_bin', 'trial_num', 'trial_context_id', 'trial_use', 'trial_first_dig', 'trial_context_index', 'trial_context_num');
        end % trial
    end % for each t-file    
end % function
