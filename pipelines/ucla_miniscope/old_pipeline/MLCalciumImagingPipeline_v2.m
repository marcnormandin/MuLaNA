classdef MLCalciumImagingPipeline < handle
    
    properties
        experimentParentFolder = '';
        analysisParentFolder = '';
        
        experiment = {};
        verbose = true;
        
        includeOtherRoi = true;
                        
        availablePerTrialTasks = { ...
            'per_trial_camerasdat_create', ...
            'per_trial_behavcam_referenceframe_create', ...
            'per_trial_behavcam_roi_create', ...
            'per_trial_behavcam_simple_tracker', ...
            'convert_dlc_to_mlbehaviourtrack', ...
            'per_trial_scopecam_alignvideo', ...
            'per_trial_scopecam_cnmfe_run', ...
            'per_trial_cnfme_spatial_footprints_save_to_cellreg', ...
            'per_trial_cnmfe_to_neuron', ...
            'ms_to_neuron', ...
            'interp_behaviour_to_scope_time_video_coordinates', ...
            'transform_video_to_rectangle_coords', ...
            'transform_video_to_square_coords', ...
            'make_allocentric_placemaps_square', ...
            'make_allocentric_placemaps_rectangle' ...
            'pipeline_dummy_test'
        };
        
        availablePerSessionTasks = { ...
            'plot_cellreg_placemaps_square', ...
            'plot_cellreg_placemaps_rectangle', ...
            'cellreg_placemap_correlation_plot_square', ...
            'cellreg_correlation_vs_orientation' ...
        };
        
        cnmfeOptions = [];
        
        config = [];
    end
    
    methods
        %%
        function obj = MLCalciumImagingPipeline(pipeline_config, experimentParentFolder, analysisParentFolder)
            
            obj.config = pipeline_config;
            obj.experimentParentFolder = experimentParentFolder;
            obj.analysisParentFolder = analysisParentFolder;
            
            obj.experiment = obj.core_pipeline_init( obj.experimentParentFolder, obj.analysisParentFolder );
            
            % Fix me
            if obj.config.verbose == 1
                obj.verbose = true;
            else
                obj.verbose = false;
            end
            
            obj.cnmfeOptions = men_cnmfe_options_create('framesPerSecond', 30, 'verbose', obj.verbose);
        end
                
        %%
        function taskReport = executeTask_AllTrials( obj, task )
            if obj.isValidPerTrialTask( task )
                % Setup a structure to record the results of the tasks
                taskReport.session = cell(obj.experiment.numSessions,1);
                taskReport.task = task;
                taskTic = tic;
                for iSession = 1:obj.experiment.numSessions
                    taskReport.session{iSession}.trial = cell(obj.experiment.session{iSession}.numTrials,1);
                end
                
                for iSession = 1:obj.experiment.numSessions
                    session = obj.getSessionByIndex(iSession);
                    sessionTic = tic;
                    
                    for iTrial = 1:obj.experiment.session{iSession}.numTrials
                        trial = obj.getTrialFromSessionByIndex(session, iTrial);

                        if obj.verbose
                            fprintf('Pipeline task ( %s ) -> Processing session %d/%d ( %s ) trial %d/%d ( %s ) \n', task, ...
                                iSession, obj.experiment.numSessions, session.name, iTrial, session.numTrials, trial.timeString );
                        end

                        trialTic = tic;
                        taskReport.session{iSession}.trial{iTrial}.success = false;
                        taskReport.session{iSession}.trial{iTrial}.error = '';

                        try
                            obj.executePerTrialTaskByIndex(task, iSession, iTrial);
                            
                            taskReport.session{iSession}.trial{iTrial}.success = true;
                        catch e
                            taskReport.session{iSession}.trial{iTrial}.success = false; % redundant
                            taskReport.session{iSession}.trial{iTrial}.error = e;
                            fprintf('Error caught: %s\n', getReport(e));
                            fprintf('Continuing with analysis.\n');
                        end
                        taskReport.session{iSession}.trial{iTrial}.computationTimeMins = toc(trialTic)/60.0;

                    end
                    
                    taskReport.session{iSession}.computationTimeMins = toc(sessionTic)/60.0;
                end

                taskReport.computationTimeMins = toc(taskTic)/60.0;
                
            else
                taskReport = {};
                fprintf('Invalid task: %s\n', task);
            end
        end
        
        %%
        function executePerSessionTaskByIndex( obj, task, iSession, varargin )
            if obj.isValidPerSessionTask( task )

                session = obj.experiment.session{iSession};
                    
                if obj.verbose
                    fprintf('Pipeline task ( %s ) -> Processing session %d/%d ( %s )\n', task, ...
                        iSession, obj.experiment.numSessions, session.name );
                end
                
                if strcmp(task, 'plot_cellreg_placemaps_square')
                    ml_cai_pipeline_cellreg_placemaps_square(obj, session);
                elseif strcmp(task, 'plot_cellreg_placemaps_rectangle')
                    ml_cai_pipeline_cellreg_placemaps_rectangle(obj, session);
                elseif strcmp(task, 'cellreg_correlation_vs_orientation')
                    ml_cai_pipeline_analysis_cellreg_correlation_vs_orientation(obj, session, varargin);
                else
                    fprintf('Error! Invalid session task.\n');
                    error('Invalid session task (%s).', task);
                end
            else
                fprintf('Error! Invalid session stask.\n');
            end
        end
        
        %%
        function executePerTrialTaskByIndex( obj, task, iSession, iTrial, varargin )
            if obj.isValidPerTrialTask( task )
                fprintf('Running excutePerTrialTaskByIndex( %s, %d, %d )\n', task, iSession, iTrial)
                
                session = obj.getSessionByIndex(iSession);
                trial = obj.getTrialFromSessionByIndex(session, iTrial);
                
                if strcmp(task, 'per_trial_camerasdat_create')
                    per_trial_camerasdat_create(obj, trial);
                elseif strcmp(task, 'per_trial_behavcam_referenceframe_create')
                    per_trial_behavcam_referenceframe_create(obj, trial);
                elseif strcmp(task, 'per_trial_behavcam_roi_create')
                    per_trial_behavcam_roi_create(obj, trial);
                elseif strcmp(task, 'per_trial_behavcam_simple_tracker')
                    per_trial_behavcam_simple_tracker(obj, trial);
                elseif strcmp(task, 'convert_dlc_to_mlbehaviourtrack')
                    ml_cai_pipeline_convert_dlc_to_mlbehaviourtrack_per_trial(obj, trial);
                elseif strcmp(task, 'per_trial_scopecam_alignvideo')
                    per_trial_scopecam_alignvideo(obj, trial);
                elseif strcmp(task, 'per_trial_scopecam_cnmfe_run')
                    per_trial_scopecam_cnmfe_run(obj, trial);
                elseif strcmp(task, 'ms_to_neuron')
                    ml_cai_pipeline_ms_to_neuron(obj, trial);
                elseif strcmp(task, 'per_trial_cnmfe_to_neuron')
                    per_trial_cnmfe_to_neuron(obj, trial);
                elseif strcmp(task, 'interp_behaviour_to_scope_time_video_coordinates')
                    interp_behaviour_to_scope_time_video_coordinates(obj, trial);
                elseif strcmp(task, 'transform_video_to_rectangle_coords')
                    ml_cai_pipeline_video_to_rectangle_coords(obj, trial);
                elseif strcmp(task, 'transform_video_to_square_coords')
                    ml_cai_pipeline_video_to_square_coords(obj, trial);
                elseif strcmp(task, 'make_allocentric_placemaps_square')
                    ml_cai_pipeline_make_allocentric_placemaps_square(obj, trial);
                elseif strcmp(task, 'make_allocentric_placemaps_rectangle')
                    ml_cai_pipeline_make_allocentric_placemaps_rectangle(obj, trial);
                elseif strcmp(task, 'per_trial_cnfme_spatial_footprints_save_to_cellreg')
                    per_trial_cnfme_spatial_footprints_save_to_cellreg(obj, session, trial);
                elseif strcmp(task, 'pipeline_dummy_test')
                    ml_cai_pipeline_dummy_test(obj, session, trial);
                end
            else
                error('Invalid trial task (%s).', task);
            end
        end
        
    end
    
    methods (Access = private)
        %%
        function taskFound = isValidPerTrialTask(obj, task)
            taskFound = obj.isValidTask(obj.availablePerTrialTasks, task);
        end
        
        %%
        function taskFound = isValidPerSessionTask(obj, task)
            taskFound = obj.isValidTask(obj.availablePerSessionTasks, task);
        end
        
        %%
        function taskFound = isValidTask( obj, availableTasks, task )
           taskFound = false;
           for iTask = 1:length(availableTasks)
               if strcmp( task, availableTasks(iTask) )
                   taskFound = true;
                   break;
               end
           end           
        end
        
        %%
        function session = getSessionByIndex(obj, iSession)
            numSessions = obj.experiment.numSessions;
            if iSession < 0 || iSession > numSessions
                error('Invalid session index (%d)')
            end
            session = obj.experiment.session{iSession};
        end
        
        %%
        function trial = getTrialFromSessionByIndex(obj, session, iTrial)
            numTrials = session.numTrials;
            if iTrial < 0 || iTrial > numTrials
                error('Invalid trial index');
            end
            trial = session.trial{iTrial};
        end
        
        
        %%
        function [experiment] = core_pipeline_init( obj, experimentParentFolder, analysisParentFolder )
            VERBOSE = obj.verbose;
            
            expDescFilename = fullfile(experimentParentFolder, 'experiment_description.json');
            exp = ml_cai_exp_loader(expDescFilename, experimentParentFolder);
            
            experiment.info = jsondecode(fileread(expDescFilename));
            experiment.subjectName = experiment.info.animal;
            experiment.dataset = experiment.info.experiment;
            experiment.ledColours = experiment.info.led_tracking_colours;

            % Create the analysis folder if it doesn't already exist
            if ~isfolder(analysisParentFolder)
                if VERBOSE
                    fprintf('Creating analysis folder (%s) ... ', analysisParentFolder);
                end
                mkdir(analysisParentFolder);
                if VERBOSE
                    fprintf('done!\n');
                end
            end

            numSessions = length(experiment.info.session_folders);
            session = cell(numSessions,1);

            for iSession = 1:numSessions

                sessionFolder = fullfile(experimentParentFolder, experiment.info.session_folders{iSession});

                trialFolders = ml_cai_io_trialfolders_find(sessionFolder);
                numTrials = length(trialFolders);

                session{iSession}.rawFolder = sessionFolder;
                session{iSession}.name = experiment.info.session_folders{iSession};
                session{iSession}.numTrials = numTrials;
                session{iSession}.trial = cell(numTrials,1);

                % Create the analysis session folder if it doesn't already exist
                analysisSessionFolder = fullfile(analysisParentFolder, experiment.info.session_folders{iSession});
                session{iSession}.analysisFolder = analysisSessionFolder;

                if ~isfolder(analysisSessionFolder)
                    if VERBOSE
                        fprintf('Creating analysis session folder (%s) ... ', analysisSessionFolder);
                    end
                    mkdir(analysisSessionFolder);
                    if VERBOSE
                        fprintf('done!\n');
                    end
                end

                for iTrial = 1:numTrials
                    fprintf('Session %d -> Trial %d -> %s\n', iSession, iTrial, trialFolders(iTrial).name);

                    trial.rawFolder = [sessionFolder filesep trialFolders(iTrial).name];
                    trial.analysisFolder = [analysisParentFolder filesep session{iSession}.name filesep trialFolders(iTrial).name];
                    trial.timeString = trialFolders(iTrial).name;

                    s = split(trialFolders(iTrial).folder, filesep);
                    trial.dateString = s{end}; % Use the parent folder of the trial as the date string
                    trial.trialNum = iTrial;

                    session{iSession}.trial{iTrial} = trial;
                    
                    % Create the analysis folder if it doesn't already exist
                    analysisSessionTrialFolder = [analysisParentFolder filesep session{iSession}.name filesep trialFolders(iTrial).name];
                    if ~isfolder(analysisSessionTrialFolder)
                        if VERBOSE
                            fprintf('Creating analysis trial folder (%s) ... ', analysisSessionTrialFolder);
                        end
                        mkdir(analysisSessionTrialFolder);
                        if VERBOSE
                            fprintf('done!\n');
                        end
                    end
                end
            end

            experiment.numSessions = numSessions;
            experiment.session = session;

        end

        %%
        function ml_cai_pipeline_dummy_test( obj, session, trial )
            fprintf('Dummy Test Function: Subject (%s) Session (%s) Trial (%s)\n', ...
                obj.experiment.subjectName, session.name, trial.timeString);
        end
        
        %%
        function per_trial_camerasdat_create( obj, trial )
            % Create the camera dat files (TEXT)
            [status, pDat] = ml_cai_daq_camerasdat_create(trial.rawFolder, 'outputFolder', trial.analysisFolder, 'verbose', obj.verbose);
            if status ~= 0
                error('Error encountered in call to ml_cai_daq_createcameradataset');
            end

            % Create the camera video records (HDF5)
            [status, pVid] = ml_cai_daq_videorecords_create(trial.rawFolder, trial.analysisFolder, obj.experiment.subjectName, obj.experiment.dataset, trial.dateString, trial.timeString, 'verbose', obj.verbose);
            if status ~= 0
                error('Error encountered in call to ml_cai_videorecordscreate');
            end

            save(fullfile(trial.analysisFolder, 'pDat.mat'), 'pDat');
            save(fullfile(trial.analysisFolder, 'pVid.mat'), 'pVid');
        end

        %%
        function per_trial_behavcam_referenceframe_create( obj, trial )
            % Compute the background frame to present to the user and use for the
            % tracker
            [pRef] = ml_cai_behavcam_referenceframe_create( trial.rawFolder, trial.analysisFolder, 'verbose', obj.verbose, 'maxFramesToUse', obj.config.behaviour_camera.background_frame.max_frames_to_use );

            save(fullfile(trial.analysisFolder, 'pRef.mat'), 'pRef');
        end % function
        
        %%
        function per_trial_behavcam_roi_create( obj, trial )
            % Ask the user to define the ROI
            [pROI] = ml_cai_behavcam_roi_create( trial.analysisFolder, 'verbose', obj.verbose, 'includeOtherROI', obj.includeOtherRoi );

            save(fullfile(trial.analysisFolder, 'pROI.mat'), 'pROI');
        end % function
        
        %%
        function per_trial_behavcam_simple_tracker( obj, trial )
            % Load the ROI
            % FIX ME -> This should get the filename programatically
            roiMatFilename = [trial.analysisFolder filesep 'behavcam_roi.mat'];
            x = load(roiMatFilename, 'behavcam_roi');
            behavcam_roi = x.behavcam_roi;
    
            % Track the behaviour
            mlvidrec = MLVideoRecord( fullfile(trial.analysisFolder, 'behav.hdf5') );
            
            tracker = MLBehaviourTracker;
            
            tracker.runall(trial.rawFolder, mlvidrec, behavcam_roi, obj.experiment.ledColours, ...
                obj.config.behaviour_camera.simple_tracker.const_a, ...
                obj.config.behaviour_camera.simple_tracker.binnerize, ...
                obj.config.behaviour_camera.simple_tracker.gaussFiltFactor, ...
                obj.config.behaviour_camera.simple_tracker.scaleWithIntensity, ...
                obj.config.behaviour_camera.simple_tracker.floor_weight, ...
                obj.config.behaviour_camera.simple_tracker.wall_weight, ...
                obj.config.behaviour_camera.simple_tracker.outside_weight);
            
            track = MLBehaviourTrack( obj.experiment.ledColours, tracker.ledPos, mlvidrec.timestamp_ms );

            % Save the track
            outputFilename = fullfile(trial.analysisFolder, 'behav_track_vid.hdf5');
            if isfile(outputFilename)
                fprintf('Removing previous track ( %s ) ... ', outputFilename);
                delete(outputFilename)
                fprintf('done!\b');
            end
            track.save(outputFilename);
        end
        
        %%
        function ml_cai_pipeline_convert_dlc_to_mlbehaviourtrack_per_trial( obj, trial )
            % Track the behaviour
            mlvidrec = MLVideoRecord( fullfile(trial.analysisFolder, 'behav.hdf5') );
            
            % For now the DLC data is put into the recording folder (but
            % shouldn't be)
            %trialDLCFolder = trial.rawFolder;
            trialDLCFolder = strrep(trial.rawFolder, 'recordings', 'dlc_tracks');

            % Perform the main conversion
            track = ml_cai_dlc_to_mlbehaviourtrack(trialDLCFolder, mlvidrec.timestamp_ms);
    
            % Save the track
            outputFilename = fullfile(trial.analysisFolder, 'behav_track_vid.hdf5');
            if isfile(outputFilename)
                fprintf('Removing previous track ( %s ) ... ', outputFilename);
                delete(outputFilename)
                fprintf('done!\b');
            end
            track.save(outputFilename);
            
            
            % Make a plot of the track as a diagnostic
            h = figure;
            imshow(imadjust(rgb2gray(imread(fullfile(trial.analysisFolder, 'behavcam_background_frame.png')))))
            hold on
            plot(track.pos(:,1), track.pos(:,2), 'b.-')
            saveas(h, fullfile(trial.analysisFolder, 'behavcam_track_pos.png'));
            close(h);
        end
        
        %%
        function per_trial_scopecam_alignvideo( obj, trial )
            pScopeAlign = ml_cai_scopecam_alignvideo( ...
                trial.rawFolder, 'outputFolder', trial.analysisFolder, ...
                'spatialDownsampling', obj.config.miniscope_camera.spatial_downsampling, ...
                'isNonRigid', obj.config.miniscope_camera.use_nonrigid_alignment==1, ...
                'verbose', obj.verbose );
            
            save(fullfile(trial.analysisFolder, 'pScopeAlign'), 'pScopeAlign');
        end
        
        %%
        function per_trial_scopecam_cnmfe_run( obj, trial )
            %Remove any previous results otherwise it requires user interaction
            oldCnmfeFolder = [trial.analysisFolder filesep 'msaligned_source_extraction'];
            if isfolder(oldCnmfeFolder)
               rmdir(oldCnmfeFolder, 's');
            end
            
            % Run the CNMFE
            mlvidrecScope = MLVideoRecord([trial.analysisFolder filesep 'scope.hdf5']);
            %cnmfeOptions = men_cnmfe_options_create('framesPerSecond', mlvidrecScope.videoFramesPerSecond, 'verbose', obj.verbose);
            obj.cnmfeOptions.Fs = mlvidrecScope.videoFramesPerSecond;
            % The CNMFe uses the 'msaligned' video which is saved by a
            % previous phase into the 'analysis' folder
            
            alignedScopeFilenameFull = fullfile(trial.analysisFolder, 'msaligned.avi');
            [cnmfe, pCnmfe] = ml_cai_cnmfe_compute( obj.cnmfeOptions, alignedScopeFilenameFull, 'verbose', obj.verbose );
            save(fullfile(trial.analysisFolder, 'cnmfe.mat'),'-v7.3', 'cnmfe');
            save(fullfile(trial.analysisFolder, 'pCnmfe'), '-v7.3', 'pCnmfe');
        end
        
        %%
        function ml_cai_pipeline_ms_to_neuron( obj, trial )
            %Remove any previous results otherwise it requires user interaction
            neuronFilename = [trial.analysisFolder filesep 'neuron.hdf5'];
            if isfile(neuronFilename)
               delete(neuronFilename);
               if obj.verbose
                   fprintf('Deleted file: %s\n', neuronFilename);
               end
            end
            
            % Run the CNMFE
            mlvidrecScope = MLVideoRecord([trial.analysisFolder filesep 'scope.hdf5']);
                        
            %maxIterations = 1000;
            x = load(fullfile(trial.analysisFolder, 'ms.mat'));
            
            % Update the sampling rate
            obj.cnmfeOptions.Fs = double(mlvidrecScope.videoFramesPerSecond);
            pDeconv_options = ml_cai_fixerupper_ms_deconvolve_cnmfe_to_neuron_hdf5(neuronFilename, x.ms, obj.cnmfeOptions.deconv_options);
            save(fullfile(trial.analysisFolder, 'pDeconv_options'), 'pDeconv_options');
        end
        
        %%
        function per_trial_cnmfe_to_neuron( obj, trial )
            %Remove any previous results otherwise it requires user interaction
            neuronFilename = [trial.analysisFolder filesep 'neuron.hdf5'];
            if isfile(neuronFilename)
               delete(neuronFilename);
               if obj.verbose
                   fprintf('Deleted file: %s\n', neuronFilename);
               end
            end
            
            % Run the CNMFE
            %mlvidrecScope = MLVideoRecord([trial.analysisFolder filesep 'scope.hdf5']);
                        
            %maxIterations = 1000;
            x = load(fullfile(trial.analysisFolder, 'cnmfe.mat'));
            
            ml_cai_create_neuron_hdf5(neuronFilename, x.cnmfe.RawTraces, x.cnmfe.FiltTraces, x.cnmfe.neuron.S', x.cnmfe.SFPs);
        end
        
        %%
        % This cleans and interoplates the raw coordinates from the tracker
        % to those of the scope time stamps since they are not at the same
        % time and the data needs to be cleaned.
        function interp_behaviour_to_scope_time_video_coordinates( obj, trial )
            numLeds = length(obj.experiment.ledColours);
            if numLeds == 1
                interp_behaviour_to_scope_time_video_coordinates_one_led(obj, trial);
            elseif numLeds == 2
                interp_behaviour_to_scope_time_video_coordinates_two_led(obj, trial);
            else
                error('interp_behaviour_to_scope_time_video_coordinates only works with either 1 or 2 led tracking (not %d)', numLeds);
            end
        end
        
        %%
        function interp_behaviour_to_scope_time_video_coordinates_one_led( obj, trial )
            % Scope data
            mlvidrecScope = MLVideoRecord([trial.analysisFolder filesep 'scope.hdf5']);
                        
            % Behaviour data from one of the trackers
            track = MLBehaviourTrack([trial.analysisFolder filesep 'behav_track_vid.hdf5']);
          
            % These are for ALL of the frames
            scopeTime = double(mlvidrecScope.timestamp_ms);
            behavTime = double(track.timestamp_ms);
            behavPosLed1 = double(track.ledPos{1}(:,1:2)); % skip third column which represents 'quality'
            behavPosLed1TrackerQ = double(track.quality); % quality from the tracker
            behavPosLed1TrackerQ(behavPosLed1TrackerQ ~= 0) = 1;
            
            % CheckMe. Added 2020-02-05. Set the quality to bad for points
            % outside the ROI. The DLC tracker doesn't use the ROI for
            % any quality checks, but we can.
            roiMatFilename = [trial.analysisFolder filesep 'behavcam_roi.mat'];
            x = load(roiMatFilename, 'behavcam_roi');
            behavcam_roi = x.behavcam_roi;
            inFloor = inpolygon(behavPosLed1(:,1), behavPosLed1(:,2), behavcam_roi.inside.j, behavcam_roi.inside.i);
            behavPosLed1TrackerQ(~inFloor | behavPosLed1TrackerQ == 1) = 1;

            % Now filter by the quality of the frames
            % 4, 10, 75
            quality = ml_cai_quality_all_one_led(behavTime, behavPosLed1, 'differenceFactor', obj.config.behaviour_camera.quality.difference_factor, 'qtracker', behavPosLed1TrackerQ);
            
            behavFramesUsed = find(quality == 0);
            behavFramesNotUsed = find(quality ~= 0);
            
            N = length(quality);
            M = sum(quality == 0);
            framesUsedPercent = M/N*100; % percent of frames that are bad quality

            % Get only the behaviour data that passes the quality check
            behavTimeQ = behavTime(quality == 0);
            behavPosLed1Q = behavPosLed1(quality == 0,:);

            [scopeLedPos1, scopePos] = ml_cai_behaviour_in_scope_coordinates_one_led(scopeTime, behavTimeQ, behavPosLed1Q);
            
            behaviour_scope_videocoords.ledPos1 = scopeLedPos1;
            behaviour_scope_videocoords.pos = scopePos;
            
            behaviour_scope_videocoords.behavFramesUsed = behavFramesUsed;
            behaviour_scope_videocoords.behavFramesNotUsed = behavFramesNotUsed;
            behaviour_scope_videocoords.behavFramesUsedPercent = framesUsedPercent;
            behaviour_scope_videocoords.quality = quality;
            
            outputFilename = fullfile(trial.analysisFolder, 'behaviour_scope_videocoords.mat');
            fprintf('Saving data to %s\n', outputFilename);
            save(outputFilename, 'behaviour_scope_videocoords');
            
            h = ml_cai_pipeline_trial_view_track_differences(trial.analysisFolder);
            outputFigureFilename = fullfile(trial.analysisFolder, 'behav_scope_videocoords.fig');
            fprintf('Saving diagnostic figure to %s\n', outputFigureFilename);
            savefig(h, outputFigureFilename);
            outputPlotFilename = fullfile(trial.analysisFolder, 'behav_scope_videocoords.png');
            fprintf('Saving diagnostic figure to %s\n', outputPlotFilename);
            saveas(h, outputPlotFilename, 'png');
            close(h);
        end
        
        %%
        function interp_behaviour_to_scope_time_video_coordinates_two_led( obj, trial )
            % Scope data
            mlvidrecScope = MLVideoRecord([trial.analysisFolder filesep 'scope.hdf5']);
                        
            % Behaviour data
            track = MLBehaviourTrack([trial.analysisFolder filesep 'behav_track_vid.hdf5']);
          
            % These are for ALL of the frames
            scopeTime = double(mlvidrecScope.timestamp_ms);
            behavTime = double(track.timestamp_ms);
            behavPosLed1 = double(track.ledPos{1}(:,1:2));
            behavPosLed2 = double(track.ledPos{2}(:,1:2));
            
            % Now filter by the quality of the frames
            % 4, 10, 75
            quality = ml_cai_quality_all_two_led(behavTime, behavPosLed1, behavPosLed2, 'differenceFactor', obj.config.behaviour_camera.quality.difference_factor, 'separationMin', obj.config.quality.separation_min, 'separationMax', obj.config.quality.separation_max);
            
            behavFramesUsed = find(quality == 0);
            behavFramesNotUsed = find(quality ~= 0);
            
            N = length(quality);
            M = sum(quality == 0);
            framesUsedPercent = M/N*100; % percent of frames that are bad quality

            % Get only the behaviour data that passes the quality check
            behavTimeQ = behavTime(quality == 0);
            behavPosLed1Q = behavPosLed1(quality == 0,:);
            behavPosLed2Q = behavPosLed2(quality == 0,:);

            [scopeLedPos1, scopeLedPos2, scopePos, scopeLookRad, scopeLookRadOther] = ml_cai_behaviour_in_scope_coordinates_two_leds(scopeTime, behavTimeQ, behavPosLed1Q, behavPosLed2Q);
            scopeLookDeg = rad2deg(scopeLookRad);
            scopeLookDegOther = rad2deg(scopeLookRadOther);
            
            behaviour_scope_videocoords.ledPos1 = scopeLedPos1;
            behaviour_scope_videocoords.ledPos2 = scopeLedPos2;
            behaviour_scope_videocoords.pos = scopePos;
            behaviour_scope_videocoords.lookDeg = scopeLookDeg;
            behaviour_scope_videocoords.lookRad = scopeLookRad;
            behaviour_scope_videocoords.lookDegOther = scopeLookDegOther;
            behaviour_scope_videocoords.lookRadOther = scopeLookRadOther;
            behaviour_scope_videocoords.behavFramesUsed = behavFramesUsed;
            behaviour_scope_videocoords.behavFramesNotUsed = behavFramesNotUsed;
            behaviour_scope_videocoords.behavFramesUsedPercent = framesUsedPercent;
            behaviour_scope_videocoords.quality = quality;
            
            outputFilename = fullfile(trial.analysisFolder, 'behaviour_scope_videocoords.mat');
            fprintf('Saving data to %s\n', outputFilename);
            save(outputFilename, 'behaviour_scope_videocoords');
        end
        
        %% transform from video coordinates to canonical rectangle
        function ml_cai_pipeline_video_to_rectangle_coords(obj, trial)
            tfolder = trial.analysisFolder;

            d1 = load( fullfile(tfolder, 'behavcam_roi.mat') );

            % The coordinates of the reference points in the video frame (pixels)
            refVidPts = [d1.behavcam_roi.inside.j'; d1.behavcam_roi.inside.i'];

            % The coordinates of the reference points in the canonical frame
            % For the rectangle/square, the feature is at the top/north
%             a = [0, obj.config.placemaps_rect.width];
%             b = [0, 0];
%             c = [obj.config.placemaps_rect.length, 0];
%             d = [obj.config.placemaps_rect.length, obj.config.placemaps_rect.width];
            a = [obj.config.allocentric_placemaps_rectangle.width, 0];
            b = [0, 0];
            c = [0, obj.config.allocentric_placemaps_rectangle.length];
            d = [obj.config.allocentric_placemaps_rectangle.width, obj.config.allocentric_placemaps_rectangle.length];
            refCanPts = [a(1), b(1), c(1), d(1); a(2), b(2), c(2), d(2)];

            % Get the transformation matrix
            v = homography_solve(refVidPts, refCanPts);

            % The behaviour data in the video coordinates
            d2 = load( fullfile(tfolder, 'behaviour_scope_videocoords.mat') );
            behav = d2.behaviour_scope_videocoords;

            % Transform the two led positions canonical coordinates
            % and then compute the angle
            x1 = homography_transform(behav.pos', v);
        
            pos = x1';
            
            fprintf('Saving results canonical rectangle coordinates... ');
            save(fullfile(tfolder, 'behaviour_scope_rectanglecoords.mat'), 'pos');
            fprintf('done!\n');
            
            h = figure;
            subplot(1,2,1)
            plot(behav.pos(:,1), behav.pos(:,2), 'k.')
            set(gca, 'ydir', 'reverse')
            axis equal
            title('Video Frame')
            
            subplot(1,2,2)
            plot(pos(:,1), pos(:,2), 'b.')
            set(gca, 'ydir', 'reverse')
            axis equal
            title('Rectangle Frame')
            
            saveas(h, fullfile(tfolder, 'behaviour_scope_rectanglecoords.png'), 'png');
            
            close(h);
        end % function
        
        %% transform from video coordinates to canonical square
        function ml_cai_pipeline_video_to_square_coords(obj, trial)
            tfolder = trial.analysisFolder;

            d1 = load( fullfile(tfolder, 'behavcam_roi.mat') );

            % The coordinates of the reference points in the video frame (pixels)
            refVidPts = [d1.behavcam_roi.inside.j'; d1.behavcam_roi.inside.i'];

            % The coordinates of the reference points in the canonical frame
            % For the rectangle/square, the feature is at the top/north
%             a = [0, obj.config.placemaps_rect.width];
%             b = [0, 0];
%             c = [obj.config.placemaps_rect.length, 0];
%             d = [obj.config.placemaps_rect.length, obj.config.placemaps_rect.width];
            a = [obj.config.allocentric_placemaps_square.width, 0];
            b = [0, 0];
            c = [0, obj.config.allocentric_placemaps_square.width];
            d = [obj.config.allocentric_placemaps_square.width, obj.config.allocentric_placemaps_square.width];
            refCanPts = [a(1), b(1), c(1), d(1); a(2), b(2), c(2), d(2)];

            % Get the transformation matrix
            v = homography_solve(refVidPts, refCanPts);

            % The behaviour data in the video coordinates
            d2 = load( fullfile(tfolder, 'behaviour_scope_videocoords.mat') );
            behav = d2.behaviour_scope_videocoords;

            % Transform the two led positions canonical coordinates
            % and then compute the angle
            x1 = homography_transform(behav.pos', v);
        
            pos = x1';
            
            fprintf('Saving results canonical square coordinates... ');
            save(fullfile(tfolder, 'behaviour_scope_squarecoords.mat'), 'pos');
            fprintf('done!\n');
            
            h = figure;
            subplot(1,2,1)
            plot(behav.pos(:,1), behav.pos(:,2), 'k.')
            set(gca, 'ydir', 'reverse')
            axis equal
            title('Video Reference Frame')
            
            subplot(1,2,2)
            plot(pos(:,1), pos(:,2), 'b.')
            set(gca, 'ydir', 'reverse')
            axis equal
            title('Square Reference Frame')
            
            saveas(h, fullfile(tfolder, 'behaviour_scope_squarecoords.png'), 'png');
            
            close(h);
        end % function
        
        %% Make the allocentric placemaps of the arenas mapped to a square where the feature is at the top
        function ml_cai_pipeline_make_allocentric_placemaps_square(obj, trial)
            trialFolder = trial.analysisFolder;
            outputFolder = fullfile(trialFolder, obj.config.allocentric_placemaps_square.output_folder);

            subjectName = obj.experiment.subjectName;

            calciumActivityType = obj.config.allocentric_placemaps.calcium_activity_type;
            calciumActivityThreshold = obj.config.allocentric_placemaps.calcium_activity_threshold;
            
            tmp = load(fullfile(trialFolder, 'behaviour_scope_squarecoords.mat'), 'pos');
            pos = tmp.pos;

            ts_ms = double(h5read( fullfile(trialFolder, 'scope.hdf5'), '/timestamp_ms' ));
       
            numNeurons = h5readatt(fullfile(trialFolder, 'neuron.hdf5'), '/', 'num_neurons');
            
            
            trialCellNumsToProcess = 1:numNeurons;
            for iCell = 1:length(trialCellNumsToProcess)
                trialCellNum = trialCellNumsToProcess(iCell);
                calciumActivityData = h5read( fullfile(trialFolder, 'neuron.hdf5'), sprintf('/neuron_%d/%s', trialCellNum, calciumActivityType) );

                if strcmp(calciumActivityType, 'spikes')
                    si = find(calciumActivityData > calciumActivityThreshold);
                else
                    [probValues, probEdges] = histcounts(calciumActivityData, 'normalization', 'probability');
                    cumProb = cumsum(probValues);
                    p = calciumActivityThreshold;
                    criticalIndex = find(cumProb > 1 - p, 1, 'first');
                    criticalValue = probEdges(criticalIndex);
                    pi = find(calciumActivityData > criticalValue);
                    
                    ci = find(h5read( fullfile(trialFolder, 'neuron.hdf5'), sprintf('/neuron_%d/%s', trialCellNum, 'spikes') ) > 0 );
                    
                    si = intersect(pi, ci);
                end

                if length(ts_ms) ~= length(calciumActivityData)
                    error('The time series length (%d) is not the same length as the calcium activity data (%d)', length(ts_ms), length(calciumActivityData))
                end

                x = pos(:,1);
                y = pos(:,2);
                
                % This version projected points to the bounds.
                boundsx = [0, obj.config.allocentric_placemaps_square.width];
                boundsy = boundsx;
                nbinsx = obj.config.allocentric_placemaps_square.nbins;
                nbinsy = nbinsx;
                
                % Now we need to filter out the outliers that result from
                % the commutator, and that are outside of the interior
                % walls of the arena, so find the valid indices
                xgi = find((x >= boundsx(1) & x <= boundsx(2))==1);
                ygi = find((y >= boundsy(1) & y <= boundsy(2))==1);
                gi = intersect(xgi, ygi);
                xg = x(gi);
                yg = y(gi);
                ts_ms_g = ts_ms(gi);
                sig_old = intersect(si, gi); % These are the spikes that are still valid, but indices into the old array
                sig = zeros(1,length(sig_old)); % Valid spikes indices into the new arrays
                for isig = 1:length(sig)
                    tt = find(sig_old(isig) == gi);
                    if length(tt) ~= 1
                        error('Logic error!')
                    end
                    sig(isig) = tt;
                end
                
                % This version maps the points to inside the bounds, and
                % does not project. It can give incorrect results if there
                % are too many points that were not tracked well and are
                % outside the arena due to things like the commutator being
                % tracked instead of the led(s).
%                 boundsx = [min(x), max(x)]
%                 boundsy = [min(y), max(y)]
%                 nbinsx = obj.config.allocentric_placemaps_square.nbins;
%                 nbinsy = nbinsx;
                mlcalciumallocentricplacemapsquare = MLCalciumPlacemap(xg, yg, ts_ms_g, sig, boundsx, boundsy, nbinsx, nbinsy, ...,
                    'GaussianSigmaBeforeDivision', obj.config.allocentric_placemaps.gaussian_sigma_before_division, ...
                    'GaussianSigmaAfterDivision', obj.config.allocentric_placemaps.gaussian_sigma_after_division, ...
                    'CriteriaDwellTimeSecondsPerBinMinimum', obj.config.allocentric_placemaps.criteria_dwell_time_seconds_per_bin_minimum, ...
                    'CriteriaSpeedCmPerSecondMinimum', obj.config.allocentric_placemaps.criteria_speed_cm_per_second_minimum, ...
                    'CriteriaSpeedCmPerSecondMaximum', obj.config.allocentric_placemaps.criteria_speed_cm_per_second_maximum, ...
                    'CriteriaSpikesPerBinMinimum', obj.config.allocentric_placemaps.criteria_spikes_per_bin_minimum, ...
                    'CriteriaInformationBitsPerSecondMinimum', obj.config.allocentric_placemaps.criteria_information_bits_per_second_minimum, ...
                    'CriteriaInformationBitsPerSpikeMinimum', obj.config.allocentric_placemaps.criteria_information_bits_per_spike_minimum);
                
                % Save the data
                if ~isfolder(outputFolder)
                    mkdir(outputFolder)
                end

                fnPrefix = sprintf('cell_%d_mlcalciumallocentricplacemapsquare', trialCellNum);
                placemapFilename = fullfile(outputFolder, sprintf('%s.mat', fnPrefix));
                fprintf('Saving placemap data to file: %s\n', placemapFilename);
                save(placemapFilename, 'mlcalciumallocentricplacemapsquare', 'trialFolder', 'trialCellNum', 'calciumActivityType', 'calciumActivityThreshold', 'outputFolder', 'subjectName');

                if obj.config.allocentric_placemaps_square.save_individual_plots == 1
                    h = figure('name', sprintf('Cell %d', trialCellNum));
                    subplot(1,2,1)
                    mlcalciumallocentricplacemapsquare.plot_path_with_spikes()
                    subplot(1,2,2)
                    mlcalciumallocentricplacemapsquare.plot()
                    %shading interp

                    saveas(h, fullfile(outputFolder, sprintf('%s.png', fnPrefix)), 'png');

                    close(h);
                end
            end %cell
        end % function
        
        %% Make the allocentric placemaps of the arenas mapped to a rectangle where the feature is at the top
        function ml_cai_pipeline_make_allocentric_placemaps_rectangle(obj, trial)
            trialFolder = trial.analysisFolder;
            outputFolder = fullfile(trialFolder, obj.config.allocentric_placemaps_rectangle.output_folder);

            subjectName = obj.experiment.subjectName;

            calciumActivityType = obj.config.allocentric_placemaps.calcium_activity_type;
            calciumActivityThreshold = obj.config.allocentric_placemaps.calcium_activity_threshold;

            tmp = load(fullfile(trialFolder, 'behaviour_scope_rectanglecoords.mat'), 'pos');
            pos = tmp.pos;

            ts_ms = double(h5read( fullfile(trialFolder, 'scope.hdf5'), '/timestamp_ms' ));
       
            numNeurons = h5readatt(fullfile(trialFolder, 'neuron.hdf5'), '/', 'num_neurons');
            
            
            trialCellNumsToProcess = 1:numNeurons;
            for iCell = 1:length(trialCellNumsToProcess)
                trialCellNum = trialCellNumsToProcess(iCell);
                calciumActivityData = h5read( fullfile(trialFolder, 'neuron.hdf5'), sprintf('/neuron_%d/%s', trialCellNum, calciumActivityType) );

                if strcmp(calciumActivityType, 'spikes')
                    si = find(calciumActivityData > calciumActivityThreshold);
                else
                    [probValues, probEdges] = histcounts(calciumActivityData, 'normalization', 'probability');
                    cumProb = cumsum(probValues);
                    p = calciumActivityThreshold;
                    criticalIndex = find(cumProb > 1 - p, 1, 'first');
                    criticalValue = probEdges(criticalIndex);
                    pi = find(calciumActivityData > criticalValue);
                    
                    ci = find(h5read( fullfile(trialFolder, 'neuron.hdf5'), sprintf('/neuron_%d/%s', trialCellNum, 'spikes') ) > 0 );
                    
                    si = intersect(pi, ci);
                end

                if length(ts_ms) ~= length(calciumActivityData)
                    error('The time series length (%d) is not the same length as the calcium activity data (%d)', length(ts_ms), length(calciumData))
                end

                x = pos(:,1);
                y = pos(:,2);
                
                % This version will project the points
                boundsx = [0, obj.config.allocentric_placemaps_rectangle.width];
                boundsy = [0, obj.config.allocentric_placemaps_rectangle.length];
                nbinsx = obj.config.allocentric_placemaps_rectangle.nbins_width;
                nbinsy = obj.config.allocentric_placemaps_rectangle.nbins_length;

                % Now we need to filter out the outliers that result from
                % the commutator, and that are outside of the interior
                % walls of the arena, so find the valid indices
                xgi = find((x >= boundsx(1) & x <= boundsx(2))==1);
                ygi = find((y >= boundsy(1) & y <= boundsy(2))==1);
                gi = intersect(xgi, ygi);
                xg = x(gi);
                yg = y(gi);
                ts_ms_g = ts_ms(gi);
                sig_old = intersect(si, gi); % These are the spikes that are still valid, but indices into the old array
                sig = zeros(1,length(sig_old)); % Valid spikes indices into the new arrays
                for isig = 1:length(sig)
                    tt = find(sig_old(isig) == gi);
                    if length(tt) ~= 1
                        error('Logic error!')
                    end
                    sig(isig) = tt;
                end
                
                % This version maps the points to inside the bounds, and
                % does not project. It can give incorrect results if there
                % are too many points that were not tracked well and are
                % outside the arena due to things like the commutator being
                % tracked instead of the led(s).
%                 boundsx = [min(x), max(x)];
%                 boundsy = [min(y), max(y)];
                %nbinsx = obj.config.allocentric_placemaps_square.nbins;
                %nbinsy = nbinsx;
                
                mlcalciumallocentricplacemaprectangle = MLCalciumPlacemap(xg, yg, ts_ms_g, sig, boundsx, boundsy, nbinsx, nbinsy, ...,
                    'GaussianSigmaBeforeDivision', obj.config.allocentric_placemaps.gaussian_sigma_before_division, ...
                    'GaussianSigmaAfterDivision', obj.config.allocentric_placemaps.gaussian_sigma_after_division, ...
                    'CriteriaDwellTimeSecondsPerBinMinimum', obj.config.allocentric_placemaps.criteria_dwell_time_seconds_per_bin_minimum, ...
                    'CriteriaSpeedCmPerSecondMinimum', obj.config.allocentric_placemaps.criteria_speed_cm_per_second_minimum, ...
                    'CriteriaSpeedCmPerSecondMaximum', obj.config.allocentric_placemaps.criteria_speed_cm_per_second_maximum, ...
                    'CriteriaSpikesPerBinMinimum', obj.config.allocentric_placemaps.criteria_spikes_per_bin_minimum, ...
                    'CriteriaInformationBitsPerSecondMinimum', obj.config.allocentric_placemaps.criteria_information_bits_per_second_minimum, ...
                    'CriteriaInformationBitsPerSpikeMinimum', obj.config.allocentric_placemaps.criteria_information_bits_per_spike_minimum);

                % Save the data
                if ~isfolder(outputFolder)
                    mkdir(outputFolder)
                end

                fnPrefix = sprintf('cell_%d_mlcalciumallocentricplacemaprectangle', trialCellNum);
                placemapFilename = fullfile(outputFolder, sprintf('%s.mat', fnPrefix));
                fprintf('Saving placemap data to file: %s\n', placemapFilename);
                save(placemapFilename, 'mlcalciumallocentricplacemaprectangle', 'trialFolder', 'trialCellNum', 'calciumActivityType', 'calciumActivityThreshold', 'outputFolder', 'subjectName');

                if obj.config.allocentric_placemaps_rectangle.save_individual_plots == 1
                    h = figure('name', sprintf('Cell %d', trialCellNum));
                    subplot(1,2,1)
                    mlcalciumallocentricplacemaprectangle.plot_path_with_spikes()
                    subplot(1,2,2)
                    mlcalciumallocentricplacemaprectangle.plot()

                    saveas(h, fullfile(outputFolder, sprintf('%s.png', fnPrefix)), 'png');

                    close(h);
                end
            end %cell
        end % function
        
        %%
        function per_trial_cnfme_spatial_footprints_save_to_cellreg(obj, session, trial)
            cellRegFolder = [session.analysisFolder filesep obj.config.cell_registration.session_sfp_output_folder];
            
            % Check if the cellreg folder exists
            if ~isfolder(cellRegFolder)
                mkdir(session.analysisFolder, obj.config.cell_registration.session_sfp_output_folder);
            end
            
            cnmfeFilename = fullfile(trial.analysisFolder, obj.config.miniscope_camera.cnmfe.cnmfe_data_filename);
            if ~isfile(cnmfeFilename)
                error('Unable to load the file (%s).\n', cnmfeFilename);
            end
            
            % this needs to be switchable with ms.mat
            x = load( cnmfeFilename );
            ms = x.cnmfe;
            for cell_i = 1:size(ms.SFPs,3)
                SFP_temp = ms.SFPs(:,:,cell_i);
                SFP_temp(SFP_temp<0.5*max(max(SFP_temp))) = 0; % This is to sharpen footprints, based on Ziv lab method
                SFP(cell_i,:,:) = SFP_temp;
            end

            % Save a copy in the 'cellreg' folder for the session
            sfp_filename = sprintf('sfp_%0.3d.mat', trial.trialNum);
            save( fullfile(cellRegFolder, sfp_filename), 'SFP', '-v7.3'); 
            
            % Save a copy local to the trial
            save( fullfile(trial.analysisFolder, 'sfp.mat'), 'SFP', '-v7.3' );
        end
        
        
        
        
        %% This is refactored version
        function ml_cai_pipeline_cellreg_placemaps_square(obj, session)
            cell_to_index_map = obj.cellreg_get_cell_to_index_map(session);

            numTrials = size(cell_to_index_map,2);

            if numTrials ~= session.numTrials
                error('The number of registered trials (%d) does not match the actual number of session trials (%d).\n', numTrials, session.numTrials);
            end

            numCells = size(cell_to_index_map,1);
            fprintf('There are a total of %d cells.\n', numCells);
            
            for iCell = 1:numCells
                fprintf('Processing placemap for cell %d of %d.\n', iCell, numCells);
                
                cellTrialIndices = cell_to_index_map(iCell,:);
                numMatches = sum( cellTrialIndices ~= 0 );
                if numMatches >= obj.config.plot_cellreg_allocentric_placemaps.minimium_trials_required_to_plot  
                    h = figure('Name', sprintf('Cell Reg Num %d', iCell), 'Position', get(0,'Screensize'));
                    if numTrials <= 8
                        p = 2; q = 4; k = 0; % Celia uses 8 trials
                    elseif numTrials <= 12
                        p = 3; q = 4; k = 0; % Matt uses 12 trials
                    elseif numTrials > 12 && numTrials <= 16
                        p = 4; q = 4; k = 0;
                    else
                        error('Too many trials (%d) to plot! Must be <= 16\n', numTrials);
                    end

                    % For the given registered cell, we will plot its
                    % placemaps across the trials on one plot
                    for iTrial = 1:numTrials
                        k = k + 1;

                        trialCellNum = cellTrialIndices(iTrial);
                        hasMatch = (trialCellNum ~= 0);
                        if hasMatch

                            trial = session.trial{iTrial};
                            dfn = fullfile(trial.analysisFolder, obj.config.allocentric_placemaps_square.output_folder, sprintf('cell_%d_mlcalciumallocentricplacemapsquare.mat', trialCellNum));
                            if ~isfile(dfn)
                                error('The required file ( %s ) does not exist!', dfn);
                            end
                            
                            tmp = load(dfn);
                            pm = tmp.mlcalciumallocentricplacemapsquare;
                            subplot(p,q,k)
                            
                            if obj.config.plot_cellreg_allocentric_placemaps.zero_bins_as_white
                                [nr,nc] = size(pm.meanFiringRateMapSmoothedPlot);
                                pcolor( [pm.meanFiringRateMapSmoothedPlot, nan(nr,1); nan(1,nc+1)] )
                            else
                                [nr,nc] = size(pm.meanFiringRateMapSmoothed);
                                pcolor( [pm.meanFiringRateMapSmoothed, nan(nr,1); nan(1,nc+1)] )
                            end
                            if strcmp(obj.config.plot_cellreg_allocentric_placemaps.shading, 'flat')
                                shading flat;
                            elseif strcmp(obj.config.plot_cellreg_allocentric_placemaps.shading, 'interp')
                                shading interp;
                            else
                                error('The value for plot_cellreg_allocentric_placemaps_square.shading is invalid. Must be interp or flat');
                            end                            
                            set(gca, 'ydir', 'reverse');
                            axis image off
                            colormap jet 
                            title(sprintf('T%d (%s) C%d', iTrial, trial.timeString, trialCellNum), 'Interpreter', 'none')
                            axis equal
                        end
                    end

                    outputFolder = fullfile(session.analysisFolder, obj.config.plot_cellreg_allocentric_placemaps_square.output_folder);
                    if ~isfolder(outputFolder)
                        mkdir(outputFolder);
                    end

                    F = getframe(h);
                    imwrite(F.cdata, fullfile(outputFolder, sprintf('%s_%s_%s_cellreg_%d.png',obj.experiment.subjectName, obj.experiment.dataset, session.name, iCell)), 'png')
                    close(h);
                end % if it has matches
            end % per cell
        end % function
        
        %% Refactored version
        function ml_cai_pipeline_cellreg_placemaps_rectangle(obj, session)
            cell_to_index_map = obj.cellreg_get_cell_to_index_map(session);

            numTrials = size(cell_to_index_map,2);

            if numTrials ~= session.numTrials
                error('The number of registered trials (%d) does not match the actual number of session trials (%d).\n', numTrials, session.numTrials);
            end

            numCells = size(cell_to_index_map,1);
            fprintf('There are a total of %d cells.\n', numCells);
            
            for iCell = 1:numCells
                fprintf('Processing placemap for cell %d of %d.\n', iCell, numCells);
                
                cellTrialIndices = cell_to_index_map(iCell,:);
                numMatches = sum( cellTrialIndices ~= 0 );
                if numMatches >= obj.config.plot_cellreg_allocentric_placemaps.minimium_trials_required_to_plot  
                    h = figure('Name', sprintf('Cell Reg Num %d', iCell), 'Position', get(0,'Screensize'));
                    if numTrials <= 8
                        numRows = 2; numCols = 4; % Celia uses 8 trials
                    elseif numTrials <= 12
                        numRows = 2; numCols = 6; % Matt uses 12 trials
                    elseif numTrials > 12 && numTrials <= 16
                        numRows = 2; numCols = 8;
                    else
                        error('Too many trials (%d) to plot! Must be <= 16\n', numTrials);
                    end
                    
                    % This will gives us the correct indices for
                    % the plots
                    numVerticalPlotsPerTrial = 2;
                    tmp1=1:(numRows*numCols*numVerticalPlotsPerTrial);
                    tmp2=reshape(tmp1,numCols, numRows*numVerticalPlotsPerTrial)';
                    k1=reshape(tmp2(1:numVerticalPlotsPerTrial:end,:)',1,numel(tmp2(1:numVerticalPlotsPerTrial:end,:)));
                    k2=reshape(tmp2(2:numVerticalPlotsPerTrial:end,:)',1,numel(tmp2(2:numVerticalPlotsPerTrial:end,:)));
                            

                    % For the given registered cell, we will plot its
                    % placemaps across the trials on one plot
                    for iTrial = 1:numTrials
                        trialCellNum = cellTrialIndices(iTrial);
                        hasMatch = (trialCellNum ~= 0);
                        if hasMatch

                            trial = session.trial{iTrial};
                            dfn = fullfile(trial.analysisFolder, obj.config.allocentric_placemaps_rectangle.output_folder, sprintf('cell_%d_mlcalciumallocentricplacemaprectangle.mat', trialCellNum));
                            if ~isfile(dfn)
                                error('The required file ( %s ) does not exist!', dfn);
                            end
                            
                            tmp = load(dfn);
                            pm = tmp.mlcalciumallocentricplacemaprectangle;
                            


                            
                            % Scatter plot
                            subplot(numRows*numVerticalPlotsPerTrial, numCols, k1(iTrial))
                            pm.plot_path_with_spikes()
                            title(sprintf('T%d (%s) C%d', iTrial, trial.timeString, trialCellNum), 'Interpreter', 'none')

                            % Ratemap
                            subplot(numRows*numVerticalPlotsPerTrial, numCols, k2(iTrial))
                            
                            if obj.config.plot_cellreg_allocentric_placemaps.zero_bins_as_white
                                [nr,nc] = size(pm.meanFiringRateMapSmoothed);
                                xx = pm.meanFiringRateMapSmoothed;
                                xx(pm.visitedCountMap==0) = nan; 
                                pcolor( [xx, nan(nr,1); nan(1,nc+1)] )
                            else
                                [nr,nc] = size(pm.meanFiringRateMapSmoothed);
                                pcolor( [pm.meanFiringRateMapSmoothed, nan(nr,1); nan(1,nc+1)] )
                            end
                            if strcmp(obj.config.plot_cellreg_allocentric_placemaps.shading, 'flat')
                                shading flat;
                            elseif strcmp(obj.config.plot_cellreg_allocentric_placemaps.shading, 'interp')
                                shading interp;
                            else
                                error('The value for plot_cellreg_allocentric_placemaps.shading is invalid. Must be interp or flat');
                            end                            
                            set(gca, 'ydir', 'reverse');
                            axis image off
                            colormap jet 
                            axis equal
                            title(sprintf('(%0.2f, %0.2f) Hz\n (%0.2f b/s, %0.2f b)', pm.peakFiringRate, pm.meanFiringRate, pm.informationRate, pm.informationPerSpike), 'Interpreter', 'none')
                        end
                    end

                    outputFolder = fullfile(session.analysisFolder, obj.config.plot_cellreg_allocentric_placemaps_rectangle.output_folder);
                    if ~isfolder(outputFolder)
                        mkdir(outputFolder);
                    end

                    F = getframe(h);
                    imwrite(F.cdata, fullfile(outputFolder, sprintf('%s_%s_%s_cellreg_%d.png',obj.experiment.subjectName, obj.experiment.dataset, session.name, iCell)), 'png')
                    close(h);
                end % if it has matches
            end % per cell
        end % function
        
        
        %%
        function ml_cai_pipeline_analysis_cellreg_correlation_vs_orientation(obj, session, context_id)
            cell_to_index_map = obj.cellreg_get_cell_to_index_map(session);

            numTrials = size(cell_to_index_map,2);

            if numTrials ~= session.numTrials
                error('The number of registered trials (%d) does not match the actual number of session trials (%d).\n', numTrials, session.numTrials);
            end

            numCells = size(cell_to_index_map,1);
            fprintf('There are a total of %d cells.\n', numCells);
            
            if isempty(context_id)
                fprintf('Correlating with all contexts.\n');
            end
            
            numProcessedCells = 0;
            
            for iCell = 1:numCells
                fprintf('Processing placemap for cell %d of %d.\n', iCell, numCells);
                
                cellTrialIndices = cell_to_index_map(iCell,:);
                
%                 if isempty(context_id)
                    numMatches = sum( cellTrialIndices ~= 0 );
%                 else
%                     numMatches = 0;
%                     matchingIds = find(cellTrialIndices ~= 0);
%                     
                        
                
                if numMatches >= obj.config.analysis_cellreg_correlation_vs_orientation.minimium_trials_in_order_to_be_included
                    
                    % Store each placemap so we don't continually waste
                    % time reloading them
                    cellPlacemaps = cell(numMatches,1);
                    k = 0;
                    for iTrial = 1:numTrials
                        trialCellNum = cellTrialIndices(iTrial);
                        hasMatch = (trialCellNum ~= 0);
                        if hasMatch
                            k = k + 1;
                            trial = session.trial{iTrial};
                            dfn = fullfile(trial.analysisFolder, obj.config.allocentric_placemaps_square.output_folder, sprintf('cell_%d_mlcalciumallocentricplacemapsquare.mat', trialCellNum));
                            if ~isfile(dfn)
                                error('The required file ( %s ) does not exist!', dfn);
                            end
                            
                            tmp = load(dfn);
                            cellPlacemaps{k} = tmp.mlcalciumallocentricplacemapsquare;
                        end
                    end
                    
                    % Now compute the pixel-pixel cross-correlation for
                    % each pair of placemaps that are not identical
                    ck = 0;
                    v = [];
                    vind = [];
                    for iMap1 = 1:length(cellPlacemaps)
                        for iMap2 = iMap1+1:length(cellPlacemaps)
                            
                            % Apply criteria for the inclusion of the maps
                            % in the results.
                            % Information rate criteria
                            minInformationRate = obj.config.analysis_cellreg_correlation_vs_orientation.criteria_information_bits_per_second_minimum;
                            if cellPlacemaps{iMap1}.informationRate < minInformationRate || cellPlacemaps{iMap2}.informationRate < minInformationRate
                                continue;
                            end
                            
                            if obj.config.analysis_cellreg_correlation_vs_orientation.use_smoothed_plot
                                T1 = cellPlacemaps{iMap1}.meanFiringRateMapSmoothed;
                                T2 = cellPlacemaps{iMap2}.meanFiringRateMapSmoothed;
                            else
                                T1 = cellPlacemaps{iMap1}.meanFiringRateMap;
                                T2 = cellPlacemaps{iMap2}.meanFiringRateMap;
                            end
                            
                            W1 = ones(size(T1));
                            W2 = ones(size(T2));
                            if obj.config.analysis_cellreg_correlation_vs_orientation.use_visited_bins_that_are_zero ~= 1
                                W1(cellPlacemaps{iMap1}.visitedCountMap == 0) = 0;
                                W2(cellPlacemaps{iMap2}.visitedCountMap == 0) = 0;
                            end
                            
                            
                            [vck, vindck] = ml_core_max_pixel_rotated_pixel_cross_correlation_square(T1, T2, 'W1', W1, 'W2', W2);
                            
                            % Only include results that had a value larger
                            % than zero because there is the off-chance
                            % that we compared with completely zero maps
                            if vck > 0
                                ck = ck + 1;
                                v(ck) = vck;
                                vind(ck) = vindck;
                            end
                        end
                    end
                    
                    if ~isempty(v) && ~isempty(vind)
                        numProcessedCells = numProcessedCells + 1;

                        % Store the results
                        per_cell_correlation_vs_orientation{numProcessedCells}.cellreg_num = iCell;
                        per_cell_correlation_vs_orientation{numProcessedCells}.v = v;
                        per_cell_correlation_vs_orientation{numProcessedCells}.vind = vind;
                        per_cell_correlation_vs_orientation{numProcessedCells}.num_comparisons = length(v);
                    end
                end % if it has matches
            end % per cell
            
            % Now compute the totals and store all of the results
            % This assumes that we have at least one
            numAngles = 4;
            angle_counts = zeros(1, numAngles);
            for i = 1:length(per_cell_correlation_vs_orientation)
                for iAngle = 1:numAngles
                    angle_counts(iAngle) = angle_counts(iAngle) + length(find(per_cell_correlation_vs_orientation{i}.vind == iAngle));
                end
            end
            angle_probs = angle_counts ./ sum(angle_counts);
            angles = (0:numAngles-1).*90;
            
            outputFolder = fullfile(session.analysisFolder, obj.config.analysis_cellreg_correlation_vs_orientation.output_folder);
            if ~isfolder(outputFolder)
                mkdir(outputFolder);
            end
            outputFile = 'cellreg_correlation_vs_orientation.mat';
            save(fullfile(outputFolder, outputFile), 'per_cell_correlation_vs_orientation', 'angle_counts', 'angle_probs', 'angles', 'numAngles');
            
            h = figure('Name', sprintf('%s', session.name), 'Position', get(0,'Screensize'));
            bar(angles, angle_probs)
            xlabel('Rotation Amount (deg)')
            ylabel('Proportion')
            grid on
            title(sprintf('%s %s [Plotted %s, minMatches %d]', obj.experiment.subjectName, session.name, datestr(now), obj.config.analysis_cellreg_correlation_vs_orientation.minimium_trials_in_order_to_be_included), 'Interpreter', 'none')
            saveas(h, fullfile(outputFolder, sprintf('%s_cellreg_correlation_vs_orientation.png', session.name)), 'png')
            close(h)
            
        end % function
        
        
        
        %%
        function [cell_to_index_map] = cellreg_get_cell_to_index_map(obj, session)
            % Load the cell registration data
            cellRegFolder = [session.analysisFolder filesep obj.config.cell_registration.session_sfp_output_folder];
            if ~isfolder(cellRegFolder)
                error('The cellreg folder (%s) does not exist. We can not make placemaps.\n', cellRegFolder);
            end
            d = dir(fullfile(cellRegFolder, 'cellRegistered*.mat'));
            if length(d) ~= 1
                error('Unable to find a single cellRegistered mat file.\n');
            end
            cellRegFilename = [d.folder filesep d.name];
            if obj.verbose
                fprintf('Loading cellreg structure from ( %s ) ...', cellRegFilename);
            end
            x = load( cellRegFilename );
            if obj.verbose
                fprintf('done!\n');
            end
            cell_to_index_map = x.cell_registered_struct.cell_to_index_map;
        end
    end
end


