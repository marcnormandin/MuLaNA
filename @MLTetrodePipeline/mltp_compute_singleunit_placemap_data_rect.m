function mltp_compute_singleunit_placemap_data_rect(obj, session)
%     if obj.config.use_d1_xlsx == 1
%         d1xlsxFilename = fullfile(session.rawFolder, 'd1.xlsx');
%         fprintf('Reading %s ... ', d1xlsxFilename);
%         [~,~,d1xlsx] = xlsread(d1xlsxFilename);
%         fprintf('done!\n');
%     end

    % Form the grid
    %boundsx = obj.config.placemaps_rect.bounds_x;
    %boundsy = obj.config.placemaps_rect.bounds_y;
    

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
            
            % Compute the number of bins we need in each dimension
            % The bounds are in cm
            cm_per_bin = obj.config.placemaps.cm_per_bin;
            nbinsx = ceil((movement.boundsX(2) - movement.boundsX(1))/cm_per_bin); 
            nbinsy = ceil((movement.boundsY(2) - movement.boundsY(1))/cm_per_bin);

            mltetrodeplacemap = MLSpikePlacemap(movement.x_cm, movement.y_cm, movement.timestamps_ms, spike_ts_ms, ...
                'speed_cm_per_second', movement.speed_smoothed_cm_per_s, ...
                'boundsx', movement.boundsX, ...
                'boundsy', movement.boundsY, ...
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
            outputFolder = fullfile(session.analysisFolder, obj.config.canon_rect_placemaps_folder);
            if ~isfolder(outputFolder)
                mkdir(outputFolder)
            end


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
            placemapFilename = fullfile(outputFolder, sprintf('%s_%d_mltetrodeplacemaprect.mat', fnPrefix, trialId));
            fprintf('Saving placemap data to file: %s\n', placemapFilename);
            save(placemapFilename, 'mltetrodeplacemap', 'cm_per_bin', 'trial_num', 'trial_context_id', 'trial_use', 'trial_first_dig', 'trial_context_index', 'trial_context_num');
        end % trial



    end % for each t-file    
end % function