classdef MLCalciumImagingPipeline_v1 < handle
    
    properties
        experimentParentFolder = '';
        analysisParentFolder = '';
        
        experiment = {};
        verbose = true;
        includeOtherRoi = true;
                
        trackerParams = {};
        
        availableTasks = {'phase_1', 'phase_2', 'phase_3', 'phase_4', ...
            'convert_dlc_to_mlbehaviourtrack', ...
            'phase_5', 'phase_6', ...
            'ms_to_neuron', 'cnmfe_to_neuron', ...
            'interp_behaviour_to_scope_time_video_coordinates', ...
            'transform_video_to_rectangle_coords', ...
            'transform_video_to_square_coords', ...
            'make_allocentric_placemaps_square', ...
            'make_allocentric_placemaps_rectangle', ...
            'cellreg_prepare', 'plot_cellreg_placemaps_square', 'plot_cellreg_placemaps_rectangle', 'cellreg_placemap_correlation_plot_square', ...
            'cellreg_direction_histograms', 'cellreg_direction_histograms_experimental', ...
            'cellreg_egocentric_placemaps', ...
            'cellreg_correlation_vs_orientation', ...
            'ml_cai_pipeline_cellreg_placemaps_fluorescence'};
        
        qualityDifferenceFactor = 4;
        qualitySeparationMin = 10;
        qualitySeparationMax = 75;
        
        placeMapsSmoothIndividualMaps = false;
        placeMapsSmoothFinalMap = true;
        placeMapsSmoothSigma = 2.0;
        
        placeMapsRectangleNumBinsI = 32;
        placeMapsRectangleNumBinsJ = 22; % celia's dimensions
        placeMapMaxCellNumToPlot = 100;
        
        placeMapsCorrelationNumBins = 20;
        
        directionHistogramsSpikeThresholdQuantile = 0.85;
        
        
        
        cnmfeOptions = [];
        
        cnmfeDataFilename = 'cnmfe.mat';
        
        cellRegFolderName = 'cellreg';
        config = [];
    end
    
    methods
        function obj = MLCalciumImagingPipeline_v1(pipeline_config, experimentParentFolder, analysisParentFolder)
            
            obj.config = pipeline_config;
            obj.experimentParentFolder = experimentParentFolder;
            obj.analysisParentFolder = analysisParentFolder;
            
            obj.experiment = obj.ml_cai_pipeline_phase_0( obj.experimentParentFolder, obj.analysisParentFolder );
            
            obj.trackerParams.CONST_A = 0.8;
            obj.trackerParams.binnerize = false;
            obj.trackerParams.gaussFiltFactor = 2;
            obj.trackerParams.scaleWithIntensity = false;
            obj.trackerParams.CONST_FLOOR_WEIGHT = 1.0;
            obj.trackerParams.CONST_WALL_WEIGHT = 0.2;
            obj.trackerParams.CONST_OUTSIDE_WEIGHT = 0.0;
            
%             obj.qualityDifferenceFactor = 4;
%             obj.qualitySeparationMin = 10;
%             obj.qualitySeparationMax = 75;
            
            obj.cnmfeOptions = men_cnmfe_options_create('framesPerSecond', 30, 'verbose', obj.verbose);
        end
        
        function taskFound = isValidTask( obj, task )
           taskFound = false;
           for iTask = 1:length(obj.availableTasks)
               if strcmp( task, obj.availableTasks(iTask) )
                   taskFound = true;
                   break;
               end
           end           
        end
        
        function taskReport = executeTask( obj, task )
            if obj.isValidTask( task )
                % Setup a structure to record the results of the tasks
                taskReport.session = cell(obj.experiment.numSessions,1);
                taskReport.task = task;
                taskTic = tic;
                for iSession = 1:obj.experiment.numSessions
                    taskReport.session{iSession}.trial = cell(obj.experiment.session{iSession}.numTrials,1);
                end
                
                for iSession = 1:obj.experiment.numSessions
                    session = obj.experiment.session{iSession};
                    sessionTic = tic;
                    
                    for iTrial = 1:obj.experiment.session{iSession}.numTrials
                        trial = session.trial{iTrial};

                        if obj.verbose
                            fprintf('Pipeline task ( %s ) -> Processing session %d/%d ( %s ) trial %d/%d ( %s ) \n', task, ...
                                iSession, obj.experiment.numSessions, session.name, iTrial, session.numTrials, trial.timeString );
                        end

                        trialTic = tic;
                        taskReport.session{iSession}.trial{iTrial}.success = false;
                        taskReport.session{iSession}.trial{iTrial}.error = '';

                        try
                            if strcmp(task, 'phase_1')
                                ml_cai_pipeline_phase_1_per_trial(obj, trial);
                            elseif strcmp(task, 'phase_2')
                                ml_cai_pipeline_phase_2_per_trial(obj, trial);
                            elseif strcmp(task, 'phase_3')
                                ml_cai_pipeline_phase_3_per_trial(obj, trial);
                            elseif strcmp(task, 'phase_4')
                                ml_cai_pipeline_phase_4_per_trial(obj, trial);
                            elseif strcmp(task, 'convert_dlc_to_mlbehaviourtrack')
                                ml_cai_pipeline_convert_dlc_to_mlbehaviourtrack_per_trial(obj, trial);
                            elseif strcmp(task, 'phase_5')
                                ml_cai_pipeline_phase_5_per_trial(obj, trial);
                            elseif strcmp(task, 'phase_6')
                                ml_cai_pipeline_phase_6_per_trial(obj, trial);
                            elseif strcmp(task, 'ms_to_neuron')
                                ml_cai_pipeline_ms_to_neuron(obj, trial);
                            elseif strcmp(task, 'cnmfe_to_neuron')
                                ml_cai_pipeline_cnmfe_to_neuron(obj, trial);
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
                            elseif strcmp(task, 'cellreg_prepare')
                                ml_cai_pipeline_cellreg_prepare(obj, session, trial);
                            end
                            
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
        
        function executeSessionTask( obj, task, iSession )
            if obj.isValidTask( task )

                session = obj.experiment.session{iSession};
                    
                if obj.verbose
                    fprintf('Pipeline task ( %s ) -> Processing session %d/%d ( %s )\n', task, ...
                        iSession, obj.experiment.numSessions, session.name );
                end
                
                if strcmp(task, 'plot_cellreg_placemaps_square')
                    ml_cai_pipeline_cellreg_placemaps_square(obj, session);
                elseif strcmp(task, 'plot_cellreg_placemaps_rectangle')
                    ml_cai_pipeline_cellreg_placemaps_rectangle(obj, session);
                elseif strcmp(task, 'ml_cai_pipeline_cellreg_placemaps_fluorescence')
                    ml_cai_pipeline_cellreg_placemaps_fluorescence(obj, session);
                elseif strcmp(task, 'cellreg_placemap_correlation_plot_square')
                    ml_cai_pipeline_cellreg_placemap_correlation_plot_square(obj, session);
                elseif strcmp(task, 'cellreg_direction_histograms')
                    ml_cai_pipeline_cellreg_direction_histograms(obj, session);
                elseif strcmp(task, 'cellreg_direction_histograms_experimental')
                    ml_cai_pipeline_cellreg_direction_histograms_experimental(obj, session);
                elseif strcmp(task, 'cellreg_egocentric_placemaps')
                    ml_cai_pipeline_cellreg_egocentric_placemaps(obj, session);
                elseif strcmp(task, 'cellreg_correlation_vs_orientation')
                    ml_cai_pipeline_analysis_cellreg_correlation_vs_orientation(obj, session);
                else
                    error('Invalid session task (%s).', task);
                end
            end
        end
        
        function executeTrialTask( obj, task, iSession, iTrial )
            if obj.isValidTask( task )

                session = obj.experiment.session{iSession};
                trial = session.trial{iTrial};
                
                if obj.verbose
                    fprintf('Pipeline task ( %s ) -> Processing session %d/%d ( %s )\n', task, ...
                        iSession, obj.experiment.numSessions, session.name );
                end
                
                
                if strcmp(task, 'phase_1')
                    ml_cai_pipeline_phase_1_per_trial(obj, trial);
                elseif strcmp(task, 'phase_2')
                    ml_cai_pipeline_phase_2_per_trial(obj, trial);
                elseif strcmp(task, 'phase_3')
                    ml_cai_pipeline_phase_3_per_trial(obj, trial);
                elseif strcmp(task, 'phase_4')
                    ml_cai_pipeline_phase_4_per_trial(obj, trial);
                elseif strcmp(task, 'convert_dlc_to_mlbehaviourtrack')
                    ml_cai_pipeline_convert_dlc_to_mlbehaviourtrack_per_trial(obj, trial);
                elseif strcmp(task, 'phase_5')
                    ml_cai_pipeline_phase_5_per_trial(obj, trial);
                elseif strcmp(task, 'phase_6')
                    ml_cai_pipeline_phase_6_per_trial(obj, trial);
                elseif strcmp(task, 'ms_to_neuron')
                    ml_cai_pipeline_ms_to_neuron(obj, trial);
                elseif strcmp(task, 'cnmfe_to_neuron')
                    ml_cai_pipeline_cnmfe_to_neuron(obj, trial);
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
                elseif strcmp(task, 'cellreg_prepare')
                    ml_cai_pipeline_cellreg_prepare(obj, session, trial);
                end
            else
                error('Invalid trial task (%s).', task);
            end
        end
        
    end
    
    methods (Access = private)
        %%
        function [experiment] = ml_cai_pipeline_phase_0( obj, experimentParentFolder, analysisParentFolder )
            VERBOSE = obj.verbose;
            
            experiment.info = jsondecode(fileread(fullfile(experimentParentFolder, 'experiment_description.json')));
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

                    session{iSession}.trial{iTrial}.rawFolder = [sessionFolder filesep trialFolders(iTrial).name];
                    session{iSession}.trial{iTrial}.analysisFolder = [analysisParentFolder filesep session{iSession}.name filesep trialFolders(iTrial).name];
                    session{iSession}.trial{iTrial}.timeString = trialFolders(iTrial).name;

                    s = split(trialFolders(iTrial).folder, filesep);
                    session{iSession}.trial{iTrial}.dateString = s{end}; % Use the parent folder of the trial as the date string
                    session{iSession}.trial{iTrial}.trialNum = iTrial;

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
        function ml_cai_pipeline_phase_1_per_trial( obj, trial )
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
        function ml_cai_pipeline_phase_2_per_trial( obj, trial )
            % Compute the background frame to present to the user and use for the
            % tracker
            [pRef] = ml_cai_behavcam_referenceframe_create( trial.rawFolder, trial.analysisFolder, 'verbose', obj.verbose, 'maxFramesToUse', obj.config.behaviour_camera.background_frame.max_frames_to_use );

            save(fullfile(trial.analysisFolder, 'pRef.mat'), 'pRef');
        end % function
        
        %%
        function ml_cai_pipeline_phase_3_per_trial( obj, trial )
            % Ask the user to define the ROI
            [pROI] = ml_cai_behavcam_roi_create( trial.analysisFolder, 'verbose', obj.verbose, 'includeOtherROI', obj.includeOtherRoi );

            save(fullfile(trial.analysisFolder, 'pROI.mat'), 'pROI');
        end % function
        
        %%
        function ml_cai_pipeline_phase_4_per_trial( obj, trial )
            % Load the ROI
            % FIX ME -> This should get the filename programatically
            roiMatFilename = [trial.analysisFolder filesep 'behavcam_roi.mat'];
            x = load(roiMatFilename, 'behavcam_roi');
            behavcam_roi = x.behavcam_roi;
    
            % Track the behaviour
            mlvidrec = MLVideoRecord( fullfile(trial.analysisFolder, 'behav.hdf5') );
            
            tracker = MLBehaviourTracker;
            
            tracker.runall(trial.rawFolder, mlvidrec, behavcam_roi, obj.experiment.ledColours, ...
                obj.trackerParams.CONST_A, obj.trackerParams.binnerize, obj.trackerParams.gaussFiltFactor, obj.trackerParams.scaleWithIntensity, ...
                obj.trackerParams.CONST_FLOOR_WEIGHT, obj.trackerParams.CONST_WALL_WEIGHT, obj.trackerParams.CONST_OUTSIDE_WEIGHT);
            
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
%             % Load the ROI
%             % FIX ME -> This should get the filename programatically
%             roiMatFilename = [trial.analysisFolder filesep 'behavcam_roi.mat'];
%             x = load(roiMatFilename, 'behavcam_roi');
%             behavcam_roi = x.behavcam_roi;
    
            % Track the behaviour
            mlvidrec = MLVideoRecord( fullfile(trial.analysisFolder, 'behav.hdf5') );
            
            % For now the DLC data is put into the recording folder (but
            % shouldn't be)
            trialDLCFolder = trial.rawFolder;
            
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
        function ml_cai_pipeline_phase_5_per_trial( obj, trial )
            pScopeAlign = ml_cai_scopecam_alignvideo( ...
                trial.rawFolder, 'outputFolder', trial.analysisFolder, ...
                'spatialDownsampling', obj.config.miniscope_camera.spatial_downsampling, ...
                'isNonRigid', obj.config.miniscope_camera.use_nonrigid_alignment, ...
                'verbose', obj.verbose );
            
            save(fullfile(trial.analysisFolder, 'pScopeAlign'), 'pScopeAlign');
        end
        
        %%
        function ml_cai_pipeline_phase_6_per_trial( obj, trial )
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
            save(fullfile(trial.analysisFolder, 'cnmfe.mat'), 'cnmfe');
            save(fullfile(trial.analysisFolder, 'pCnmfe'), 'pCnmfe');
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
        function ml_cai_pipeline_cnmfe_to_neuron( obj, trial )
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
            
            % Now filter by the quality of the frames
            % 4, 10, 75
            quality = ml_cai_quality_all_one_led(behavTime, behavPosLed1, 'differenceFactor', obj.qualityDifferenceFactor);
            
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
            quality = ml_cai_quality_all_two_led(behavTime, behavPosLed1, behavPosLed2, 'differenceFactor', obj.qualityDifferenceFactor, 'separationMin', obj.qualitySeparationMin, 'separationMax', obj.qualitySeparationMax);
            
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
        function ml_cai_pipeline_cellreg_prepare(obj, session, trial)
            cellRegFolder = [session.analysisFolder filesep obj.cellRegFolderName];
            
            % Check if the cellreg folder exists
            if ~isfolder(cellRegFolder)
                mkdir(session.analysisFolder, obj.cellRegFolderName);
            end
            
            % this needs to be switchable with ms.mat
            x = load( fullfile(trial.analysisFolder, obj.cnmfeDataFilename) );
            ms = x.cnmfe;
            for cell_i = 1:size(ms.SFPs,3)
                SFP_temp = ms.SFPs(:,:,cell_i);
                SFP_temp(SFP_temp<0.5*max(max(SFP_temp))) = 0; % This is to sharpen footprints, based on Ziv lab method
                SFP(cell_i,:,:) = SFP_temp;
            end

            sfp_filename = sprintf('sfp_%d.mat', trial.trialNum);
            save( fullfile(cellRegFolder, sfp_filename), 'SFP', '-v7.3'); 
        end
        
        %% A single trial
        %% egocentric placemaps and scatterplots
        
        
        %% egocentric placemaps and scatterplots
        function ml_cai_pipeline_cellreg_egocentric_placemaps(obj, session)
            % Load the cell registration data
            cellRegFolder = [session.analysisFolder filesep obj.cellRegFolderName];
            if ~isfolder(cellRegFolder)
                error('The cellreg folder (%s) does not exist. We can not make placemaps.\n', cellRegFolder);
            end
            d = dir(fullfile(cellRegFolder, 'cellRegistered*.mat'));
            if length(d) ~= 1
                error('Unable to find a single cellRegistered mat file.\n');
            end
            cellRegFilename = [d.folder filesep d.name];
            x = load( cellRegFilename );
            cell_to_index_map = x.cell_registered_struct.cell_to_index_map;

            numTrials = size(cell_to_index_map,2);

            if numTrials ~= session.numTrials
                error('The number of registered trials (%d) does not match the actual number of session trials (%d).\n', numTrials, session.numTrials);
            end

            numCells = size(cell_to_index_map,1);
            fprintf('There are a total of %d cells.\n', numCells);
            
            data = cell(session.numTrials, 1);
            for iTrial = 1:numTrials
                tfolder = session.trial{iTrial}.analysisFolder;

                d1 = load( fullfile(tfolder, 'behavcam_roi.mat') );

                % The coordinates of the reference points in the video frame (pixels)
                refVidPts = [d1.behavcam_roi.inside.i'; d1.behavcam_roi.inside.j'];

                % The coordinates of the reference points in the canonical frame
                % For the rectangle/square, the feature is at the top/north
                a = [0, 20];
                b = [0, 0];
                c = [30, 0];
                d = [30, 20];
                refCanPts = [a(1), b(1), c(1), d(1); a(2), b(2), c(2), d(2)];

                % Get the transformation matrix
                v = homography_solve(refVidPts, refCanPts);
                
                % The behaviour data
                d2 = load( fullfile(tfolder, 'behaviour_scope_videocoords.mat') );
                behav = d2.behaviour_scope_videocoords;

                % EGOCENTRIC VALUES
                % Transform the position to canonical coordinates
                x = homography_transform(behav.pos', v);
                posCan = x';

                % Transform the two led positions canonical coordinates
                % and then compute the angle
                x1 = homography_transform(behav.ledPos1', v);
                x1 = x1';
                x2 = homography_transform(behav.ledPos2', v);
                x2 = x2';
                aa = atan2(x2(:,1)- x1(:,1), x2(:,2)- x1(:,2));
                bb = find(aa < 0);
                aa(bb) = aa(bb) + 2*pi;
                lookDegCan = rad2deg(aa);

                % We need to make sure that the position is inside the arena polygon
                % or else the procedure to find the distances will fail.
                insideArena = inpolygon(posCan(:,2), posCan(:,1), refCanPts(2,:), refCanPts(1,:));
                posCan(~insideArena) = [];
                lookDegCan(~insideArena) = [];

                % The occupancy map. For every mouse position it will have a heading, and
                % we will need to compute the distances for each angle we want.
                mouseEgocentricAngles = 0:0.5:180; % only use half
                allDistances = nan(length(lookDegCan), 2*length(mouseEgocentricAngles)-1);
                poly = refCanPts';
                for iLook = 1:length(lookDegCan)
                    mouseHeadingDeg = lookDegCan(iLook);
                    mousePosition = posCan(iLook,:);
                    % allAngles will always be the same
                    [allAngles, allDistances(iLook,:)] = ml_cai_egocentric_compute_distances(mousePosition, mouseHeadingDeg, mouseEgocentricAngles, poly);
                end
                
                % Occupancy map
                occupancyNBINS = 100;

                % Form the occupancy map
                occupancyRho = allDistances;
                occupancyTHETA = repmat(allAngles, size(occupancyRho,1), 1);
                occupancyX = occupancyRho .* cosd(occupancyTHETA);
                occupancyY = occupancyRho .* sind(occupancyTHETA);
                [OM, occupancyXEDGES, occupancyYEDGES] = histcounts2(occupancyX, occupancyY, occupancyNBINS);
                %OMF = imgaussfilt(OM,2);
    
                data{iTrial}.trialFolder = tfolder;
                data{iTrial}.insideArena = insideArena; % used to filter the spikes
                data{iTrial}.posCan = posCan;
                data{iTrial}.lookDegCan = lookDegCan;
                data{iTrial}.allDistances = allDistances;
                data{iTrial}.allAngles = allAngles;
                data{iTrial}.OM = OM;
                data{iTrial}.occupancyXEDGES = occupancyXEDGES;
                data{iTrial}.occupancyYEDGES = occupancyYEDGES;
                data{iTrial}.occupancyNBINS = occupancyNBINS;
            end

            for iCell = 1:numCells
                fprintf('Processing placemap for cell %d of %d.\n', iCell, numCells);
                
                cellTrialIndices = cell_to_index_map(iCell,:);
                h = figure('Name', sprintf('Cell Reg Num %d', iCell), 'Position', get(0,'Screensize'));
                p = 3; q = 6; k = -1;

                %numMatches = sum( cellTrialIndices ~= 0 );
                matchNum = 0;

                for iTrial = 1:numTrials
                    k = k + 2;

                    trialCellNum = cellTrialIndices(iTrial);
                    hasMatch = (trialCellNum ~= 0);
                    if hasMatch
                        matchNum = matchNum + 1;

                        spikes = h5read(fullfile(data{iTrial}.trialFolder, 'neuron.hdf5'), sprintf('/neuron_%d/spikes', trialCellNum));
                        % Filter out those that happen outside the arena
                        spikes(~data{iTrial}.insideArena) = [];

                        activeIndices = find(spikes ~= 0);

                        activeDistances = data{iTrial}.allDistances(activeIndices,:);

                        activePosCan = data{iTrial}.posCan(activeIndices,:);
                        activeVal = spikes(activeIndices);
                        activeLookDegCan = data{iTrial}.lookDegCan(activeIndices);

                        % threshold
                        threshold = quantile(activeVal, 0.25);
                        badIndices = find(activeVal < threshold);
                        %activeVal(badIndices) = [];
                        activeLookDegCan(badIndices) = [];
                        activePosCan(badIndices,:) = [];

                        activeDistances(badIndices,:) = [];

                        % parameters
                        edges = 0:6:360;
                        centers = 3:6:360;
                        huelinear = linspace(0, 1, length(centers));
                        satlinear = 0.8*ones(1, length(centers));
                        vallinear = ones(1, length(centers));

                        [~, ~, bi] = histcounts(activeLookDegCan, edges);
                        activeLookColor = hsv2rgb([huelinear(bi)' satlinear(bi)' vallinear(bi)']);

                        subplot(p,q,k)
                        plot(data{iTrial}.posCan(:,2), data{iTrial}.posCan(:,1), 'k-')
                        hold on
                        scatter(activePosCan(:,2), activePosCan(:,1), 'filled', 'markerfacealpha', 0.9, 'CData', activeLookColor)
                        set(gca, 'ydir', 'reverse')
                        axis equal tight


                        % Form the activity map
                        activeRho = activeDistances;
                        activeTHETA = repmat(data{iTrial}.allAngles, size(activeRho,1), 1);
                        activeX = activeRho .* cosd(activeTHETA);
                        activeY = activeRho .* sind(activeTHETA);
                        [AM, ~, ~] = histcounts2(activeX, activeY, data{iTrial}.occupancyXEDGES, data{iTrial}.occupancyYEDGES);

                        subplot(p,q,k+1)
                        imagesc(imgaussfilt(AM ./ data{iTrial}.OM, 2))
                        colormap jet
                        colorbar
                        axis equal tight
                    end
                end

                if ~isfolder(fullfile(session.analysisFolder, 'egocentric_placemaps'))
                    mkdir(session.analysisFolder, 'egocentric_placemaps');
                end
                
                F = getframe(h);
                imwrite(F.cdata, fullfile(session.analysisFolder, 'egocentric_placemaps', sprintf('%s_%s_cell_%d_egocentric_placemaps.png',obj.experiment.subjectName, obj.experiment.dataset, iCell)), 'png')
                savefig(h, fullfile(session.analysisFolder, 'egocentric_placemaps', sprintf('%s_%s_cell_%d_egocentric_placemaps.fig',obj.experiment.subjectName, obj.experiment.dataset, iCell)));
                close(h);
            end
            
            
        end % function
        
        
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
        function ml_cai_pipeline_analysis_cellreg_correlation_vs_orientation(obj, session)
            cell_to_index_map = obj.cellreg_get_cell_to_index_map(session);

            numTrials = size(cell_to_index_map,2);

            if numTrials ~= session.numTrials
                error('The number of registered trials (%d) does not match the actual number of session trials (%d).\n', numTrials, session.numTrials);
            end

            numCells = size(cell_to_index_map,1);
            fprintf('There are a total of %d cells.\n', numCells);
            
            numProcessedCells = 0;
            
            for iCell = 1:numCells
                fprintf('Processing placemap for cell %d of %d.\n', iCell, numCells);
                
                cellTrialIndices = cell_to_index_map(iCell,:);
                numMatches = sum( cellTrialIndices ~= 0 );
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
        
        %% OLD VERSION
%         function ml_cai_pipeline_cellreg_placemaps_old(obj, session)
%             cell_to_index_map = cellreg_get_cell_to_index_map(session);
% 
%             numTrials = size(cell_to_index_map,2);
% 
%             if numTrials ~= session.numTrials
%                 error('The number of registered trials (%d) does not match the actual number of session trials (%d).\n', numTrials, session.numTrials);
%             end
% 
%             numCells = size(cell_to_index_map,1);
%             fprintf('There are a total of %d cells.\n', numCells);
%             
%             data = cell(session.numTrials, 1);
%             for iTrial = 1:numTrials
%                 tfolder = session.trial{iTrial}.analysisFolder;
% 
%                 data{iTrial}.trialFolder = tfolder;
%                 
%                 d1 = load( fullfile(tfolder, 'behavcam_roi.mat') );
% 
%                 % The coordinates of the reference points in the video frame (pixels)
%                 refVidPts = [d1.behavcam_roi.inside.i'; d1.behavcam_roi.inside.j'];
% 
%                 % The coordinates of the reference points in the canonical frame
%                 % For the rectangle/square, the feature is at the top/north
%                 a = [0, 20];
%                 b = [0, 0];
%                 c = [30, 0];
%                 d = [30, 20];
%                 refCanPts = [a(1), b(1), c(1), d(1); a(2), b(2), c(2), d(2)];
% 
%                 % Get the transformation matrix
%                 v = homography_solve(refVidPts, refCanPts);
%                 data{iTrial}.v = v;
%                 data{iTrial}.refCanPts = refCanPts';
% 
%                 % The behaviour data
%                 d2 = load( fullfile(tfolder, 'behaviour_scope_videocoords.mat') );
%                 behav = d2.behaviour_scope_videocoords;
% 
%                 % Transform to canonical coordinates
%                 posVidPts = behav.pos';
%                 x = homography_transform(posVidPts, v);
%                 posCanPts = x';
% 
%                 % Store so we don't have to keep transforming
%                 data{iTrial}.posCanPts = posCanPts;
%             end
% 
%             for iCell = 1:numCells
%                 fprintf('Processing placemap for cell %d of %d.\n', iCell, numCells);
%                 
%                 cellTrialIndices = cell_to_index_map(iCell,:);
%                 h = figure('Name', sprintf('Cell Reg Num %d', iCell), 'Position', get(0,'Screensize'));
%                 if numTrials > 8
%                     p = 3; q = 4; k = 0; % Matt uses 12 trials
%                 else
%                     p = 2; q = 4; k = 0; % Celia uses 8 trials
%                 end
% 
% 
%                 numMatches = sum( cellTrialIndices ~= 0 );
%                 activityData = cell(numMatches,1);
%                 matchNum = 0;
% 
%                 for iTrial = 1:numTrials
%                     k = k + 1;
% 
%                     trialCellNum = cellTrialIndices(iTrial);
%                     hasMatch = (trialCellNum ~= 0);
%                     if hasMatch
%                         subplot(p,q,k)
% 
%                         matchNum = matchNum + 1;
% 
%                         %nid = trialCellNum;
% 
%                         %roi = data{iTrial}.roi;
%                         trialFolder = data{iTrial}.trialFolder;
% 
%                         pos_i = data{iTrial}.posCanPts(:,1);
%                         pos_j = data{iTrial}.posCanPts(:,2);
% 
%                         activePos = [];
%                         visitedPos = [];
% 
%                         spikeData = h5read( fullfile(trialFolder, 'neuron.hdf5'), sprintf('/neuron_%d/spikes', trialCellNum) );
%                         spikeIndices = find(spikeData ~= 0);
%                         activePos(:,1) = pos_i(spikeIndices);
%                         activePos(:,2) = pos_j(spikeIndices);
% 
%                         activeVal = spikeData(spikeIndices);
% 
%                         visitedPos(:,1) = pos_i;
%                         visitedPos(:,2) = pos_j;
% 
%                         kk = matchNum;
%                         activityData{kk}.trialNum = iTrial;
%                         activityData{kk}.globalCellNum = iCell;
%                         activityData{kk}.trialCellNum = trialCellNum;
%                         activityData{kk}.activePos = activePos;
%                         activityData{kk}.activeVal = activeVal;
%                         activityData{kk}.visitedPos = visitedPos;
%                         activityData{kk}.v = data{iTrial}.v; % To simplify the other code
%                         activityData{kk}.spikeIndices = spikeIndices;
% 
% %                         [pPlacemap, placeMap] = ml_cai_placemaps_compute(visitedPos, activePos, activeVal, ...
% %                             'nbinsi', obj.placeMapsRectangleNumBinsI, 'nbinsj', obj.placeMapsRectangleNumBinsJ, ...
% %                             'sigma', obj.placeMapsSmoothSigma, ...
% %                             'smoothIndividualMaps', obj.placeMapsSmoothIndividualMaps, ...
% %                             'smoothFinalMap', obj.placeMapsSmoothFinalMap);
% 
%                         boundsi = [0 30];
%                         boundsj = [0,20];
% 
%                         [~, placeMap, activeMap, occupancyMap, notVisitedMap] = ml_cai_placemaps_compute(visitedPos, activePos, activeVal, boundsi, boundsj, ...
%                             'nbinsi', obj.placeMapsRectangleNumBinsI, 'nbinsj', obj.placeMapsRectangleNumBinsJ, ...
%                             'smoothFinalMap', obj.placeMapsSmoothFinalMap, 'smoothIndividualMaps', obj.placeMapsSmoothIndividualMaps, 'sigma', obj.placeMapsSmoothSigma);
% 
% 
%                         activityData{kk}.placeMap = placeMap;
% 
%                         
% %                         imagesc(placeMap);
% %                         colormap jet
% %                         axis equal tight
%                         % Plot the maps
%                         % Use pcolor so that nan's are white
%                         [nr,nc] = size(placeMap);
% 
%                         %figure('Name', 'Creation of placemaps using fake data')
%                         %ax(1) = subplot(1,3,1);
%                         pcolor([placeMap,  nan(nr,1); nan(1,nc+1)])
%                         shading flat;
%                         set(gca, 'ydir', 'reverse');
%                         %title('Occupancy')
%                         axis image
%                         colorbar
%                         colormap jet
% 
%                     end
%                 end
% 
%                 if ~isfolder(fullfile(session.analysisFolder, 'correlation_placemaps'))
%                     mkdir(session.analysisFolder, 'correlation_placemaps');
%                 end
%                 
%                 F = getframe(h);
%                 imwrite(F.cdata, fullfile(session.analysisFolder, 'correlation_placemaps', sprintf('%s_%s_cell_%d.png',obj.experiment.subjectName, obj.experiment.dataset, iCell)), 'png')
%                 close(h);
%             end
%             
%             
%         end % function
        
        %%
%         function ml_cai_pipeline_cellreg_placemaps_fluorescence(obj, session)
%             % Load the cell registration data
%             cellRegFolder = [session.analysisFolder filesep obj.cellRegFolderName];
%             if ~isfolder(cellRegFolder)
%                 error('The cellreg folder (%s) does not exist. We can not make placemaps.\n', cellRegFolder);
%             end
%             d = dir(fullfile(cellRegFolder, 'cellRegistered*.mat'));
%             if length(d) ~= 1
%                 error('Unable to find a single cellRegistered mat file.\n');
%             end
%             cellRegFilename = [d.folder filesep d.name];
%             x = load( cellRegFilename );
%             cell_to_index_map = x.cell_registered_struct.cell_to_index_map;
% 
%             numTrials = size(cell_to_index_map,2);
% 
%             if numTrials ~= session.numTrials
%                 error('The number of registered trials (%d) does not match the actual number of session trials (%d).\n', numTrials, session.numTrials);
%             end
% 
%             numCells = size(cell_to_index_map,1);
%             fprintf('There are a total of %d cells.\n', numCells);
%             
%             data = cell(session.numTrials, 1);
%             for iTrial = 1:numTrials
%                 tfolder = session.trial{iTrial}.analysisFolder;
% 
%                 data{iTrial}.trialFolder = tfolder;
%                 
%                 d1 = load( fullfile(tfolder, 'behavcam_roi.mat') );
% 
%                 % The coordinates of the reference points in the video frame (pixels)
%                 refVidPts = [d1.behavcam_roi.inside.i'; d1.behavcam_roi.inside.j'];
% 
%                 % The coordinates of the reference points in the canonical frame
%                 % For the rectangle/square, the feature is at the top/north
%                 a = [1, 21];
%                 b = [1, 1];
%                 c = [31, 1];
%                 d = [31, 21];
%                 refCanPts = [a(1), b(1), c(1), d(1); a(2), b(2), c(2), d(2)];
% 
%                 boundaryCanPts = [0 0 32 32; 22 0 0 22];
%                 
%                 % Get the transformation matrix
%                 v = homography_solve(refVidPts, refCanPts);
%                 data{iTrial}.v = v;
%                 data{iTrial}.refCanPts = refCanPts';
% 
%                 % The behaviour data
%                 d2 = load( fullfile(tfolder, 'behaviour_scope_videocoords.mat') );
%                 behav = d2.behaviour_scope_videocoords;
% 
%                 % Transform to canonical coordinates
%                 posVidPts = behav.pos';
%                 x = homography_transform(posVidPts, v);
%                 posCanPts = x';
% 
%                 % Filter out points outside the region that we want
%                 insideBoundaryArena = inpolygon(posCanPts(:,2), posCanPts(:,1), boundaryCanPts(2,:), boundaryCanPts(1,:));
%                 
%                 % 20191205 Removed for debugging
%                 %posCanPts(~insideBoundaryArena) = [];
%                 
%                 %lookDegCan(~insideArena) = [];
%                 
%                 % Store so we don't have to keep transforming
%                 data{iTrial}.posCanPts = posCanPts;
%                 data{iTrial}.insideBoundaryArena = insideBoundaryArena;
%             end
% 
%             maxCellNum = obj.placeMapMaxCellNumToPlot;
%             if isempty(maxCellNum)
%                 maxCellNum = numCells;
%             end
%             
%             if maxCellNum > numCells
%                 maxCellNum = numCells;
%             end
%             
%             for iCell = 1:maxCellNum
%                 fprintf('Processing placemap for cell %d of %d.\n', iCell, numCells);
%                 
%                 cellTrialIndices = cell_to_index_map(iCell,:);
%                 h = figure('Name', sprintf('Cell Reg Num %d', iCell), 'Position', get(0,'Screensize'));
%                 p = 3; q = 4; k = 0;
% 
%                 numMatches = sum( cellTrialIndices ~= 0 );
%                 activityData = cell(numMatches,1);
%                 matchNum = 0;
% 
%                 for iTrial = 1:numTrials
%                     k = k + 1;
% 
%                     trialCellNum = cellTrialIndices(iTrial);
%                     hasMatch = (trialCellNum ~= 0);
%                     if hasMatch
%                         subplot(p,q,k)
% 
%                         matchNum = matchNum + 1;
% 
%                         %nid = trialCellNum;
% 
%                         %roi = data{iTrial}.roi;
%                         trialFolder = data{iTrial}.trialFolder;
% 
%                         pos_i = data{iTrial}.posCanPts(:,1);
%                         pos_j = data{iTrial}.posCanPts(:,2);
% 
%                         activePos = [];
%                         visitedPos = [];
% 
%                         %spikeData = h5read( fullfile(trialFolder, 'neuron.hdf5'), sprintf('/neuron_%d/spikes', trialCellNum) );
%                         %spikeIndices = find(spikeData ~= 0);
%                         
%                         calciumData = h5read( fullfile(trialFolder, 'neuron.hdf5'), sprintf('/neuron_%d/trace_filt', trialCellNum) );
%                         
%                         % Filter out from the calcium the same indices
%                         % filtered from the data because it is outside the
%                         % range
%                         % FIX ME. THIS USED TO WORK
%                         %calciumData(~insideBoundaryArena) = [];
% 
%                         %qt = quantile(calciumData, 0.25);
%                         %activeIndices = find(calciumData > 0.2 & calciumData >= qt);
%                         activeIndices = find(calciumData > 0);
%                         
%                         activePos(:,1) = pos_i(activeIndices);
%                         activePos(:,2) = pos_j(activeIndices);
% 
%                         activeVal = calciumData(activeIndices);
% 
%                         visitedPos(:,1) = pos_i;
%                         visitedPos(:,2) = pos_j;
% 
%                         kk = matchNum;
%                         activityData{kk}.trialNum = iTrial;
%                         activityData{kk}.globalCellNum = iCell;
%                         activityData{kk}.trialCellNum = trialCellNum;
%                         activityData{kk}.activePos = activePos;
%                         activityData{kk}.activeVal = activeVal;
%                         activityData{kk}.visitedPos = visitedPos;
%                         activityData{kk}.v = data{iTrial}.v; % To simplify the other code
%                         activityData{kk}.activeIndices = activeIndices;
% 
%                         % Previous working version
% %                         [pPlacemap, placeMap] = ml_cai_placemaps_compute(visitedPos, activePos, activeVal, ...
% %                             'nbinsi', obj.placeMapsRectangleNumBinsI, 'nbinsj', obj.placeMapsRectangleNumBinsJ, ...
% %                             'sigma', obj.placeMapsSmoothSigma, ...
% %                             'smoothIndividualMaps', obj.placeMapsSmoothIndividualMaps, ...
% %                             'smoothFinalMap', obj.placeMapsSmoothFinalMap);
% 
%                         boundsi = [0 30];
%                         boundsj = [0,20];
% 
%                         [~, placeMap, activeMap, occupancyMap, notVisitedMap] = ml_cai_placemaps_compute(visitedPos, activePos, activeVal, boundsi, boundsj, ...
%                             'nbinsi', obj.placeMapsRectangleNumBinsI, 'nbinsj', obj.placeMapsRectangleNumBinsJ, ...
%                             'smoothFinalMap', obj.placeMapsSmoothFinalMap, 'smoothIndividualMaps', obj.placeMapsSmoothIndividualMaps, 'sigma', obj.placeMapsSmoothSigma);
%                         
%                         activityData{kk}.placeMap = placeMap;
% 
%                         imagesc(placeMap);
%                         colormap jet
%                         axis equal tight
%                     end
%                 end
% 
%                 if ~isfolder(fullfile(session.analysisFolder, 'rectangle_placemaps_calcium_trace'))
%                     mkdir(session.analysisFolder, 'rectangle_placemaps_calcium_trace');
%                 end
%                 
%                 F = getframe(h);
%                 imwrite(F.cdata, fullfile(session.analysisFolder, 'rectangle_placemaps_calcium_trace', sprintf('%s_%s_cell_%d.png',obj.experiment.subjectName, obj.experiment.dataset, iCell)), 'png')
%                 savefig(h, fullfile(session.analysisFolder, 'rectangle_placemaps_calcium_trace', sprintf('%s_%s_cell_%d.fig',obj.experiment.subjectName, obj.experiment.dataset, iCell)));
%                 save(fullfile(session.analysisFolder, 'rectangle_placemaps_calcium_trace', sprintf('%s_%s_cell_%d_rectangle_placemaps_calciumtrace.mat',obj.experiment.subjectName, obj.experiment.dataset, iCell)), 'activityData');
% 
%                 close(h);
%             end
%             
%             
%         end % function
        
        
        %% OLD VERSION
%         function ml_cai_pipeline_cellreg_placemap_correlation_plot_square(obj, session)
%             % Load the cell registration data
%             cellRegFolder = [session.analysisFolder filesep obj.cellRegFolderName];
%             if ~isfolder(cellRegFolder)
%                 error('The cellreg folder (%s) does not exist. We can not make placemaps.\n', cellRegFolder);
%             end
%             d = dir(fullfile(cellRegFolder, 'cellRegistered*.mat'));
%             if length(d) ~= 1
%                 error('Unable to find a single cellRegistered mat file.\n');
%             end
%             cellRegFilename = [d.folder filesep d.name];
%             x = load( cellRegFilename );
%             cell_to_index_map = x.cell_registered_struct.cell_to_index_map;
% 
%             numTrials = size(cell_to_index_map,2);
% 
%             if numTrials ~= session.numTrials
%                 error('The number of registered trials (%d) does not match the actual number of session trials (%d).\n', numTrials, session.numTrials);
%             end
% 
%             numCells = size(cell_to_index_map,1);
%             fprintf('There are a total of %d cells.\n', numCells);
%             
%             % For the rotation correlations across trials
%             numRotations = 4;
%             %rbest = zeros(numRotations,1);
%             rotCorr = cell(numRotations,1);
%             rotCorrPerCell = cell(numCells,1);
% 
%             data = cell(session.numTrials, 1);
%             for iTrial = 1:numTrials
%                 tfolder = session.trial{iTrial}.analysisFolder;
% 
%                 data{iTrial}.trialFolder = tfolder;
%                 
%                 d1 = load( fullfile(tfolder, 'behavcam_roi.mat') );
% 
%                 % The coordinates of the reference points in the video frame (pixels)
%                 refVidPts = [d1.behavcam_roi.inside.i'; d1.behavcam_roi.inside.j'];
% 
%                 % The coordinates of the reference points in the canonical frame
%                 % For the rectangle/square, the feature is at the top/north
%                 L = 1;
%                 a = [0, L];
%                 b = [0, 0];
%                 c = [L, 0];
%                 d = [L, L];
%                 refCanPts = [a(1), b(1), c(1), d(1); a(2), b(2), c(2), d(2)];
% 
%                 % Get the transformation matrix
%                 v = homography_solve(refVidPts, refCanPts);
%                 data{iTrial}.v = v;
%                 data{iTrial}.refCanPts = refCanPts';
% 
%                 % The behaviour data
%                 d2 = load( fullfile(tfolder, 'behaviour_scope_videocoords.mat') );
%                 behav = d2.behaviour_scope_videocoords;
% 
%                 % Transform to canonical coordinates
%                 posVidPts = behav.pos';
%                 x = homography_transform(posVidPts, v);
%                 posCanPts = x';
% 
%                 % Store so we don't have to keep transforming
%                 data{iTrial}.posCanPts = posCanPts;
%                 data{iTrial}.posVidPts = posVidPts';
%                 data{iTrial}.refVidPts = refVidPts';
%             end
% 
%             for iCell = 1:numCells
%                 fprintf('Processing placemap for cell %d of %d.\n', iCell, numCells);
%                 
%                 cellTrialIndices = cell_to_index_map(iCell,:);
%                 h = figure('Name', sprintf('Cell Reg Num %d', iCell), 'Position', get(0,'Screensize'));
%                 p = 2; q = 4; k = 0;
% 
%                 numMatches = sum( cellTrialIndices ~= 0 );
%                 activityData = cell(numMatches,1);
%                 matchNum = 0;
% 
%                 for iTrial = 1:numTrials
%                     k = k + 1;
% 
%                     trialCellNum = cellTrialIndices(iTrial);
%                     hasMatch = (trialCellNum ~= 0);
%                     if hasMatch
%                         subplot(p,q,k)
% 
%                         matchNum = matchNum + 1;
% 
%                         trialFolder = data{iTrial}.trialFolder;
% 
%                         pos_i = data{iTrial}.posCanPts(:,1);
%                         pos_j = data{iTrial}.posCanPts(:,2);
% 
%                         activePos = [];
%                         visitedPos = [];
% 
%                         spikeData = h5read( fullfile(trialFolder, 'neuron.hdf5'), sprintf('/neuron_%d/spikes', trialCellNum) );
%                         spikeIndices = find(spikeData ~= 0);
%                         activePos(:,1) = pos_i(spikeIndices);
%                         activePos(:,2) = pos_j(spikeIndices);
% 
%                         activeVal = spikeData(spikeIndices);
% 
%                         visitedPos(:,1) = pos_i;
%                         visitedPos(:,2) = pos_j;
% 
%                         kk = matchNum;
%                         activityData{kk}.trialNum = iTrial;
%                         activityData{kk}.globalCellNum = iCell;
%                         activityData{kk}.trialCellNum = trialCellNum;
%                         activityData{kk}.activePos = activePos;
%                         activityData{kk}.activeVal = activeVal;
%                         activityData{kk}.visitedPos = visitedPos;
%                         activityData{kk}.v = data{iTrial}.v; % To simplify the other code
%                         activityData{kk}.spikeIndices = spikeIndices;
% 
%                         [pPlacemap, placeMap] = ml_cai_placemaps_compute(visitedPos, activePos, activeVal, ...
%                             'nbinsi', obj.placeMapsCorrelationNumBins, 'nbinsj', obj.placeMapsCorrelationNumBins, ...
%                             'sigma', obj.placeMapsSmoothSigma, ...
%                             'smoothIndividualMaps', obj.placeMapsSmoothIndividualMaps, ...
%                             'smoothFinalMap', obj.placeMapsSmoothFinalMap);
% 
%                         activityData{kk}.placeMap = placeMap;
% 
%                         imagesc(placeMap);
%                         colormap jet
%                         axis equal square tight
%                     end
%                 end
% 
%                 % Compute temporary data for the correlation plot
%                 % Now collect the statistics
%                 %fprintf('Computing statistics ... ');
%                 kk = 0;
%                 for i = 1:length(activityData)
%                    T1 = activityData{i}.placeMap;
%                    for j = (i+1):length(activityData)
%                        % 4 rotations. 0, 90, 180, 270
%                        r = zeros(1,numRotations);
%                        for k = 1:numRotations
%                                 L = 1;
%                                 a = [0, L];
%                                 b = [0, 0];
%                                 c = [L, 0];
%                                 d = [L, L];
%                 
%                            fprintf('Rotation %d/%d\n', k, numRotations);
%                            if k == 1 % 0 degrees
%                                refCanPts = [a(1), b(1), c(1), d(1); a(2), b(2), c(2), d(2)];
%                            elseif k == 2 % 90 degrees
%                                refCanPts = [d(1), a(1), b(1), c(1); d(2), a(2), b(2), c(2)];
%                            elseif k == 3 % 180 degrees
%                                refCanPts = [c(1), d(1), a(1), b(1); c(2), d(2), a(2), b(2)];
%                            elseif k == 4 % 270
%                                refCanPts = [b(1), c(1), d(1), a(1); b(2), c(2), d(2), a(2)];
%                            else
%                                error('Invalid angle')
%                            end
%                            
%                            AD = activityData{j};
%                            trialNum = AD.trialNum;
%                            
%                            refVidPts = data{trialNum}.refVidPts; %[data{trialNum}.roi.inside.i'; data{trialNum}.roi.inside.j'];
%                         
%                             % Get the transformation matrix
%                             v = homography_solve(refVidPts', refCanPts);
%                             
%                             % Transform the visited points
% %                             posVidPts1 = [];
% %                             posVidPts1(:,1) = data{trialNum}.track.pos(AD.scopeToBehavIndices,1);
% %                             posVidPts1(:,2) = data{trialNum}.track.pos(AD.scopeToBehavIndices,2);
%                             posVidPts1 = data{trialNum}.posVidPts;
%                             x = homography_transform(posVidPts1', v);
%                             visitedPos = x';
%                             
%                             % Only take points that are inside the equilateral triangle
%                             %inVisited = inpolygon( visitedPos(:,1), visitedPos(:,2), refCanPts(1,1:4), refCanPts(2,1:4) ); % Don't use the middle point of the triangle
%                             %visitedPos(inVisited == false,:) = [];
%                             
%                             % Transform the active points
%                             %posVidPts2 = [];
%                             posVidPts2 = data{trialNum}.posVidPts(AD.spikeIndices,:);
%                             %posVidPts2(:,2) = data{trialNum}.track.pos(AD.spikeBehavIndices, 2);
%                             x = homography_transform(posVidPts2', v);
%                             activePos = x';
%                             
%                             % Only take points that are inside the equilateral triangle
%                             %inActive = inpolygon( activePos(:,1), activePos(:,2), refCanPts(1,1:4), refCanPts(2,1:4) ); % Don't use the middle point of the triangle
%                             
%                             %activePos(inActive == false,:) = [];
%                             
%                             activeVal = AD.activeVal;
%                             %activeVal(inActive == false) = [];
%                             
%                             %T2Rot = rot90(T2,k-1);
%                             [pPlacemap, T2Rot] = ml_cai_placemaps_compute(visitedPos, activePos, activeVal, ...
%                                 'nbinsi', obj.placeMapsCorrelationNumBins, 'nbinsj', obj.placeMapsCorrelationNumBins, ...
%                                 'sigma', obj.placeMapsSmoothSigma, ...
%                                 'smoothIndividualMaps', obj.placeMapsSmoothIndividualMaps, ...
%                                 'smoothFinalMap', obj.placeMapsSmoothFinalMap);
%             
%                             rr = corrcoef(T1(:), T2Rot(:));
%                             r(k) = rr(1,2);
%                        end
%             
%                        % Old version
%                        [v,vind] = max(r);
%             
%                        %rbest(vind) = rbest(vind) + 1;
%                        if isempty(rotCorr{vind})
%                            rotCorr{vind} = v;
%                        else
%                            rotCorr{vind} = [rotCorr{vind}; v];
%                        end
%                        
%                        kk = kk + 1;
%                        if isempty(rotCorrPerCell{iCell})
%                             rotCorrPerCell{iCell} = vind;
%                        else
%                             rotCorrPerCell{iCell} = [rotCorrPerCell{iCell}; vind];
%                        end
%                    end
%                 end
% 
% 
%                 if ~isfolder(fullfile(session.analysisFolder, 'correlation_placemaps'))
%                     mkdir(session.analysisFolder, 'correlation_placemaps');
%                 end
%                 
%                 F = getframe(h);
%                 imwrite(F.cdata, fullfile(session.analysisFolder, 'correlation_placemaps', sprintf('%s_%s_cell_%d.png',obj.experiment.subjectName, obj.experiment.dataset, iCell)), 'png')
%                 close(h);
%                 save(fullfile(session.analysisFolder, 'correlation_placemaps', 'rotCorr.mat'), 'rotCorr');
%                 save(fullfile(session.analysisFolder, 'correlation_placemaps', 'rotCorrPerCell.mat'), 'rotCorrPerCell');
%             end
%             
%             
%             %% Correlation histogram
%             mu = zeros(1,numRotations);
%             s = zeros(1,numRotations);
%             for k = 1:numRotations
%                 mu(k) = length(rotCorr{k}); %mean(rotCorr{k});
%                 s(k) = std(rotCorr{k}) ./ sqrt(length(rotCorr{k}));
%             end
%             mu = mu ./sum(mu) * 100;
%             fprintf('Correlation means:\n');
%             disp(mu);
%             save(fullfile(session.analysisFolder, 'correlation_placemaps', sprintf('%s_%s_correlation_histogram_mu.mat',obj.experiment.subjectName, obj.experiment.dataset)), 'mu');
% 
%                         
%             s = s * 100;
%             a=mu;
%             b=s;
%             ctr = 1:numRotations;
% 
%             figure
%             hBar = bar(ctr, a');
%             for k1 = 1:size(a,1)
%                 ctr(k1,:) = bsxfun(@plus, hBar(1).XData, [hBar(k1).XOffset]');
%                 ydt(k1,:) = hBar(k1).YData;
%             end
%             hold on
%             %e = errorbar(ctr, ydt, b, 'LineStyle','none', 'LineWidth',2, 'Color', 'k');
%             set(gca, 'xticklabel', {['0' char(176)], ['90' char(176)], ['180' char(176)], ['270' char(176)]});
%             ylim([0 50])
%             %title('Group Data', 'FontSize', 16, 'FontWeight', 'bold');
%             %xlabel('Location of first dig', 'FontSize', 14);
%             %ylabel('Probability', 'FontSize', 14);
% 
%             ytl = get(gca, 'yticklabel');
%             ytll = '';
%             for i = 1:length(ytl)
%                 ytll{i} = [ytl{i} '%'];
%             end
%             set(gca, 'yticklabel', ytll)
%             title(sprintf('%s %s', obj.experiment.subjectName, obj.experiment.dataset))
%             hold off
% 
%             savefig(fullfile(session.analysisFolder, 'correlation_placemaps', sprintf('%s_%s_correlation_histogram.fig',obj.experiment.subjectName, obj.experiment.dataset)));
%             saveas(gcf, fullfile(session.analysisFolder, 'correlation_placemaps', sprintf('%s_%s_correlation_histogram.png',obj.experiment.subjectName, obj.experiment.dataset)), 'png');
%             
%             
%         end % function
        
        
        
        %%
        function ml_cai_pipeline_cellreg_direction_histograms(obj, session)
            % Load the cell registration data
            cellRegFolder = [session.analysisFolder filesep obj.cellRegFolderName];
            if ~isfolder(cellRegFolder)
                error('The cellreg folder (%s) does not exist. We can not make placemaps.\n', cellRegFolder);
            end
            d = dir(fullfile(cellRegFolder, 'cellRegistered*.mat'));
            if length(d) ~= 1
                error('Unable to find a single cellRegistered mat file.\n');
            end
            cellRegFilename = [d.folder filesep d.name];
            x = load( cellRegFilename );
            cell_to_index_map = x.cell_registered_struct.cell_to_index_map;

            numTrials = size(cell_to_index_map,2);

            if numTrials ~= session.numTrials
                error('The number of registered trials (%d) does not match the actual number of session trials (%d).\n', numTrials, session.numTrials);
            end

            numCells = size(cell_to_index_map,1);
            fprintf('There are a total of %d cells.\n', numCells);
            
            data = cell(session.numTrials, 1);
            for iTrial = 1:numTrials
                tfolder = session.trial{iTrial}.analysisFolder;

                data{iTrial}.trialFolder = tfolder;
                
                d1 = load( fullfile(tfolder, 'behavcam_roi.mat') );

                % The coordinates of the reference points in the video frame (pixels)
                refVidPts = [d1.behavcam_roi.inside.i'; d1.behavcam_roi.inside.j'];

                % The coordinates of the reference points in the canonical frame
                % For the rectangle/square, the feature is at the top/north
                L = 1;
                a = [0, L];
                b = [0, 0];
                c = [L, 0];
                d = [L, L];
                refCanPts = [a(1), b(1), c(1), d(1); a(2), b(2), c(2), d(2)];

                % Get the transformation matrix
                v = homography_solve(refVidPts, refCanPts);
                data{iTrial}.v = v;
                data{iTrial}.refCanPts = refCanPts';

                % The behaviour data
                d2 = load( fullfile(tfolder, 'behaviour_scope_videocoords.mat') );
                behav = d2.behaviour_scope_videocoords;

                % Transform the two led positions canonical coordinates
                % and then compute the angle
                x1 = homography_transform(behav.ledPos1', v);
                x1 = x1';
                x2 = homography_transform(behav.ledPos2', v);
                x2 = x2';
                aa = atan2(x2(:,1)- x1(:,1), x2(:,2)- x1(:,2));
                bb = find(aa < 0);
                aa(bb) = aa(bb) + 2*pi;
                lookDegCan = rad2deg(aa);

                % Store so we don't have to keep transforming
                data{iTrial}.lookDegCan = lookDegCan;
            end

            for iCell = 1:numCells
                fprintf('Processing placemap for cell %d of %d.\n', iCell, numCells);
                
                cellTrialIndices = cell_to_index_map(iCell,:);
                h = figure('Name', sprintf('Cell Reg Num %d', iCell), 'Position', get(0,'Screensize'));
                p = 2; q = 4; k = 0;

                numMatches = sum( cellTrialIndices ~= 0 );
                activityData = cell(numMatches,1);
                matchNum = 0;

                % Store the data for later use
                cellTrialData = cell(numTrials,1);

                for iTrial = 1:numTrials
                    k = k + 1;

                    trialCellNum = cellTrialIndices(iTrial);
                    hasMatch = (trialCellNum ~= 0);
                    if hasMatch
                        subplot(p,q,k)

                        matchNum = matchNum + 1;

                        trialFolder = data{iTrial}.trialFolder;
                        
                        visitedLookDegCan = data{iTrial}.lookDegCan;
       
                        spikeData = h5read( fullfile(trialFolder, 'neuron.hdf5'), sprintf('/neuron_%d/spikes', trialCellNum) );
                        spikeIndices = find(spikeData ~= 0);
                        
                        activeLookDegCan = visitedLookDegCan(spikeIndices);
                        activeVal = spikeData(spikeIndices);

                        % Make the plot
                        %edges = 0:6:360; % 61 edges, 60 bins
                        %centers = 3:6:360;
                        edges = 0:12:360;
                        centers = 6:12:360;
                        visitedCounts = histcounts(visitedLookDegCan, edges);
                        [activeCounts, ~, binIndices] = histcounts(activeLookDegCan, edges);
                        activeCounts = zeros(1, length(activeCounts));
                        for iActive = 1:length(activeVal)
                            activeCounts( binIndices(iActive) ) = activeCounts( binIndices(iActive) ) + activeVal(iActive);
                        end
                        metric = activeCounts ./ visitedCounts;
                        bar(centers, metric);
                        
                        cellTrialData{iTrial}.activeCounts = activeCounts;
                        cellTrialData{iTrial}.visitedCounts = visitedCounts;
                        cellTrialData{iTrial}.globalCellNum = iCell;
                        cellTrialData{iTrial}.metric = metric;
                        cellTrialData{iTrial}.edges = edges;
                        cellTrialData{iTrial}.centers = centers;
                        cellTrialData{iTrial}.activeVal = activeVal;
                        cellTrialData{iTrial}.activeLookDegCan = activeLookDegCan;
                        cellTrialData{iTrial}.visistedLookDegCan = visitedLookDegCan;
                        
                        activityData{matchNum}.metric = metric;
                        activityData{matchNum}.centers = centers; % all centers should be the same
                    end % iTrial

                if ~isfolder(fullfile(session.analysisFolder, 'direction_histograms'))
                    mkdir(session.analysisFolder, 'direction_histograms');
                end
                    
                    save(fullfile(session.analysisFolder, 'direction_histograms', sprintf('%s_%s_cell_%d_celltrialdata.mat',obj.experiment.subjectName, obj.experiment.dataset, iCell)), 'cellTrialData');
                end % iCell

                if ~isfolder(fullfile(session.analysisFolder, 'direction_histograms'))
                    mkdir(session.analysisFolder, 'direction_histograms');
                end
                
                F = getframe(h);
                imwrite(F.cdata, fullfile(session.analysisFolder, 'direction_histograms', sprintf('%s_%s_cell_%d.png',obj.experiment.subjectName, obj.experiment.dataset, iCell)), 'png')
                close(h);
                
                
                % Now do the summed figure
                averageMetric = activityData{1}.metric;
                for iMatch = 2:numMatches
                    averageMetric = averageMetric + activityData{iMatch}.metric;
                end
                averageMetric = averageMetric ./ numMatches;
                h = figure('Name', sprintf('Cell Reg Num %d (averaged using %d trials)', iCell, numMatches), 'Position', get(0,'Screensize'));
                bar(activityData{1}.centers, averageMetric)
                F = getframe(h);
                imwrite(F.cdata, fullfile(session.analysisFolder, 'direction_histograms', sprintf('%s_%s_cellaverage_%d.png',obj.experiment.subjectName, obj.experiment.dataset, iCell)), 'png')
                close(h);
            end
            
            
        end % function
        
        
        %%
        function ml_cai_pipeline_cellreg_direction_histograms_experimental(obj, session)
            % Load the cell registration data
            cellRegFolder = [session.analysisFolder filesep obj.cellRegFolderName];
            if ~isfolder(cellRegFolder)
                error('The cellreg folder (%s) does not exist. We can not make placemaps.\n', cellRegFolder);
            end
            d = dir(fullfile(cellRegFolder, 'cellRegistered*.mat'));
            if length(d) ~= 1
                error('Unable to find a single cellRegistered mat file.\n');
            end
            cellRegFilename = [d.folder filesep d.name];
            x = load( cellRegFilename );
            cell_to_index_map = x.cell_registered_struct.cell_to_index_map;

            numTrials = size(cell_to_index_map,2);

            if numTrials ~= session.numTrials
                error('The number of registered trials (%d) does not match the actual number of session trials (%d).\n', numTrials, session.numTrials);
            end

            numCells = size(cell_to_index_map,1);
            fprintf('There are a total of %d cells.\n', numCells);
            
            data = cell(session.numTrials, 1);
            for iTrial = 1:numTrials
                tfolder = session.trial{iTrial}.analysisFolder;

                data{iTrial}.trialFolder = tfolder;
                
                d1 = load( fullfile(tfolder, 'behavcam_roi.mat') );

                % The coordinates of the reference points in the video frame (pixels)
                refVidPts = [d1.behavcam_roi.inside.i'; d1.behavcam_roi.inside.j'];

                % The coordinates of the reference points in the canonical frame
                % For the rectangle/square, the feature is at the top/north
                a = [0, 20];
                b = [0, 0];
                c = [30, 0];
                d = [30, 20];
                refCanPts = [a(1), b(1), c(1), d(1); a(2), b(2), c(2), d(2)];

                % Get the transformation matrix
                v = homography_solve(refVidPts, refCanPts);
                data{iTrial}.v = v;
                data{iTrial}.refCanPts = refCanPts';

                % The behaviour data
                d2 = load( fullfile(tfolder, 'behaviour_scope_videocoords.mat') );
                behav = d2.behaviour_scope_videocoords;

                % Transform the two led positions canonical coordinates
                % and then compute the angle
                x1 = homography_transform(behav.ledPos1', v);
                x1 = x1';
                x2 = homography_transform(behav.ledPos2', v);
                x2 = x2';
                aa = atan2(x2(:,1)- x1(:,1), x2(:,2)- x1(:,2));
                bb = find(aa < 0);
                aa(bb) = aa(bb) + 2*pi;
                lookDegCan = rad2deg(aa);

                % Store so we don't have to keep transforming
                data{iTrial}.lookDegCan = lookDegCan;
            end

            for iCell = 1:numCells
                fprintf('Processing placemap (thresholded) for cell %d of %d.\n', iCell, numCells);
                
                cellTrialIndices = cell_to_index_map(iCell,:);
                h = figure('Name', sprintf('Cell Reg Num %d', iCell), 'Position', get(0,'Screensize'));
                p = 2; q = 4; k = 0;

                numMatches = sum( cellTrialIndices ~= 0 );
                activityData = cell(numMatches,1);
                matchNum = 0;

                for iTrial = 1:numTrials
                    k = k + 1;

                    trialCellNum = cellTrialIndices(iTrial);
                    hasMatch = (trialCellNum ~= 0);
                    if hasMatch
                        subplot(p,q,k)

                        matchNum = matchNum + 1;

                        trialFolder = data{iTrial}.trialFolder;
                        
                        visitedLookDegCan = data{iTrial}.lookDegCan;
       
                        spikeData = h5read( fullfile(trialFolder, 'neuron.hdf5'), sprintf('/neuron_%d/spikes', trialCellNum) );
                        spikeIndices = find(spikeData ~= 0);
                        
                        % We will filter these below
                        activeVal = spikeData(spikeIndices);
                        activeLookDegCan = visitedLookDegCan(spikeIndices);

                        % Now out of all the spike values, find the
                        % threshold to filter them (since low ones are due
                        % to noise).
                        threshold = quantile(activeVal, obj.directionHistogramsSpikeThresholdQuantile);
                        
                        belowThresholdIndices = find(activeVal < threshold);
                        activeVal(belowThresholdIndices) = [];
                        activeLookDegCan(belowThresholdIndices) = [];
                                                

                        % Make the plot
                        %edges = 0:6:360; % 61 edges, 60 bins
                        %centers = 3:6:360;
                        %edges = 0:12:360;
                        %centers = 6:12:360;
                        edges = 0:1:360;
                        centers = 0.5:1:360;
                        visitedCounts = histcounts(visitedLookDegCan, edges);
                        [activeCounts, ~, binIndices] = histcounts(activeLookDegCan, edges);
                        activeCounts = zeros(1, length(activeCounts));
                        for iActive = 1:length(activeVal)
                            activeCounts( binIndices(iActive) ) = activeCounts( binIndices(iActive) ) + activeVal(iActive);
                        end
                        metric = activeCounts ./ visitedCounts;
                        metric = metric ./ sum(metric);
                        metric(visitedCounts==0) = 0;

                        bar(centers, metric, 'r');
                        
                        activityData{matchNum}.metric = metric;
                        activityData{matchNum}.centers = centers; % all centers should be the same
                    end
                end

                if ~isfolder(fullfile(session.analysisFolder, 'direction_histograms_experimental_extreme'))
                    mkdir(session.analysisFolder, 'direction_histograms_experimental_extreme');
                end
                
                F = getframe(h);
                imwrite(F.cdata, fullfile(session.analysisFolder, 'direction_histograms_experimental_extreme', sprintf('%s_%s_cell_%d.png',obj.experiment.subjectName, obj.experiment.dataset, iCell)), 'png')
                close(h);
                
                
                % Now do the summed figure
                averageMetric = activityData{1}.metric;
                for iMatch = 2:numMatches
                    averageMetric = averageMetric + activityData{iMatch}.metric;
                end
                averageMetric = averageMetric ./ numMatches;
                h = figure('Name', sprintf('Cell Reg Num %d (averaged using %d trials and thresholded)', iCell, numMatches), 'Position', get(0,'Screensize'));
                bar(activityData{1}.centers, averageMetric, 'r')
                F = getframe(h);
                imwrite(F.cdata, fullfile(session.analysisFolder, 'direction_histograms_experimental_extreme', sprintf('%s_%s_cellaverage_%d.png',obj.experiment.subjectName, obj.experiment.dataset, iCell)), 'png')
                close(h);
            end
            
            
        end % function
        
        %%
        function [cell_to_index_map] = cellreg_get_cell_to_index_map(obj, session)
            % Load the cell registration data
            cellRegFolder = [session.analysisFolder filesep obj.cellRegFolderName];
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


