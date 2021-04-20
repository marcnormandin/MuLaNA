classdef MLPipeline < handle
    
    properties (SetAccess = protected, GetAccess = public)

        RecordingsParentFolder
        AnalysisParentFolder
        
        Config
        
        Experiment

        % Kernel used to smooth the placemaps
        SmoothingKernelSymmetric % Used for square and rectangular arenas
        SmoothingKernelRectCompressed % Used for rectangular arena compressed to a square for the best fit analysis
        
    end
    
    properties
        Verbose = false;
    end
    
    properties %(Access = protected)
        availableTrialTasks = containers.Map('KeyType', 'char', 'ValueType', 'any');
        availableSessionTasks = containers.Map('KeyType', 'char', 'ValueType', 'any');
        availableExperimentTasks = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end
    
    methods
        function obj = MLPipeline(config, recordingsParentFolder,  analysisParentFolder)
            obj.Verbose = config.verbose;
            
            obj.Config = config;
            obj.RecordingsParentFolder = recordingsParentFolder;
            obj.AnalysisParentFolder = analysisParentFolder;
            
            obj.Experiment = MLExperimentBuilder.buildFromJson(obj.Config, recordingsParentFolder, analysisParentFolder);
            
            if ~exist(analysisParentFolder, 'dir')
                mkdir(analysisParentFolder);
                fprintf('Created analysis parent folder: %s\n', analysisParentFolder);
            end

            obj.configSetup();
        end
        
        function [b] = isVerbose(obj)
            b = obj.Verbose;
        end
        
        function printAvailableTasks(obj)
            fprintf('Per trial tasks:\n');
            if obj.availableTrialTasks.length == 0
                fprintf('\t none\n');
            else
                at = obj.availableTrialTasks;
                k = at.keys;
                for i = 1:at.length
                    fprintf('\t%s\n',k{i})
                end
            end
            fprintf('\n');
            
            fprintf('Per session tasks:\n');
            if obj.availableSessionTasks.length == 0
                fprintf('\t none\n');
            else
                at = obj.availableSessionTasks;
                k = at.keys;
                for i = 1:at.length
                    fprintf('\t%s\n',k{i})
                end
            end
            fprintf('\n');
            
            fprintf('Per experiment tasks:\n');
            if obj.availableExperimentTasks.length == 0
                fprintf('\t none\n');
            else
                at = obj.availableExperimentTasks;
                k = at.keys;
                for i = 1:at.length
                    fprintf('\t%s\n',k{i})
                end
            end
        end
        
        function taskReport = executeTask_AllTrials( obj, task )
            if obj.isValidTrialTask( task )
                % Setup a structure to record the results of the tasks
                taskReport.session = cell(obj.Experiment.getNumSessions(),1);
                taskReport.task = task;
                taskTic = tic;
                for iSession = 1:obj.Experiment.getNumSessions()
                    session = obj.Experiment.getSession(iSession);
                    taskReport.session{iSession}.trial = cell(session.getNumTrials(),1);
                end
                
                % Execute the task
                for iSession = 1:obj.Experiment.getNumSessions()
                    session = obj.Experiment.getSession(iSession);
                    sessionTic = tic;
                    
                    for iTrial = 1:session.getNumTrials()
                        if obj.Verbose
                            fprintf('Pipeline task ( %s ) -> Processing session %d/%d ( %s ) trial %d/%d \n', task, ...
                                iSession, obj.Experiment.getNumSessions(), session.getName(), iTrial, session.getNumTrials() );
                        end

                        trialTic = tic;
                        taskReport.session{iSession}.trial{iTrial}.success = false;
                        taskReport.session{iSession}.trial{iTrial}.error = '';

                        try
                            % EXECUTE THE TASK
                            obj.executeTrialTaskByIndices(task, iSession, iTrial);
                            
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
        
        % Experiment Tasks
        function executeExperimentTask(obj, task)
            if obj.isValidExperimentTask( task )
                % execute the task
                func = obj.availableExperimentTasks(task);
                func();
            end
        end
        
        % Loop over Session Tasks
        function executePerSessionTask( obj, task )
            for iSession = 1:obj.Experiment.getNumSessions()
                obj.executeSessionTaskByIndex(task, iSession);
            end
        end
        
        % Sesion By index
        function executeSessionTaskByIndex( obj, task, iSession )
            if obj.isValidSessionTask( task )
                session = obj.Experiment.getSession(iSession);
                obj.executeSessionTask( task, session );
            else
                error('Invalid task');
            end
        end
        
        % Session by Session
        function executeSessionTask( obj, task, session )
            if obj.isValidSessionTask( task )

                if obj.Verbose
                    fprintf('Pipeline task ( %s ) -> Processing session ( %s )\n', task, ...
                         session.getName() );
                end
                
                % execute the session task
                func = obj.availableSessionTasks(task);

                
                % Use this for miniscope
                func(obj,session);
                
                % Use this for tetrode
                %func(session);
            end
        end
        
        
        
        % Per trial
        function executePerTrialTask( obj, task )
            for iSession = 1:obj.Experiment.getNumSessions()
                session = obj.Experiment.getSession(iSession);
                for iTrial = 1:session.getNumTrials()
                    trial = session.getTrial(iTrial);
                    if trial.isEnabled()
                        obj.executeTrialTask(task, session, trial);
                    end
                end
            end
        end
    
        function executeTrialTaskByIndices( obj, task, iSession, iTrial )
            session = obj.Experiment.getSession(iSession);
            trial = session.getTrial(iTrial);
            obj.executeTrialTask(task, session, trial);
        end
        
        function executeTrialTask( obj, task, session, trial )
            if obj.isValidTrialTask( task )

                if obj.Verbose
                    fprintf('Pipeline task ( %s ) -> Processing session (%s) trial ( %s )\n', task, ...
                          session.getName(), trial.getName());
                end
                
                % execute the trial task
                func = obj.availableTrialTasks(task);
                func(session, trial);
            else
                error('Invalid trial task (%s).', task);
            end
        end
        
    end
    
    methods (Access = protected)
        function registerTrialTask(obj, task, fun)
            obj.availableTrialTasks(task) = fun;
        end
        
        function registerSessionTask(obj, task, fun)
            obj.availableSessionTasks(task) = fun;
        end
        
        function registerExperimentTask(obj, task, fun)
            obj.availableExperimentTasks(task) = fun;
        end
        
        function configSetup(obj)
            if obj.Config.verbose == 1
                obj.Config.verbose = true;
                obj.Verbose = true;
            else
                obj.Config.verbose = false;
                obj.Verbose = false;
            end
            
            obj.configSetupSmoothingKernels();
            
            obj.configValidateSpeed();
        end
        
        function configSetupSmoothingKernels(obj)
            % Kernel for rectangle (symmetric kernel, and so bins should be squares (eg. 1cm x 1cm)            
            obj.SmoothingKernelSymmetric = ml_util_compute_rect_kernel(obj.Config.placemaps.smoothingKernelGaussianSize_cm, obj.Config.placemaps.smoothingKernelGaussianSigma_cm, obj.Config.placemaps.cm_per_bin_rect_both_dim);

            % Kernel for compressed rectangle (assymetric kernel, real bin
            % size is not square (eg. 1x1.5 cm bins)
            arena = obj.Experiment.getArenaGeometry();
            if strcmpi(arena.shape, 'rectangle') 
                arenaLengthRatio = arena.x_length_cm / arena.y_length_cm;
                obj.SmoothingKernelRectCompressed = ml_util_compute_rect_compressed_kernel(arenaLengthRatio, obj.Config.placemaps.smoothingKernelGaussianSize_cm, obj.Config.placemaps.smoothingKernelGaussianSigma_cm, obj.Config.placemaps.cm_per_bin_square_smallest_dim);
            else
                obj.SmoothingKernelRectCompressed = obj.SmoothingKernelSymmetric;   
            end
        end
        
        function configValidateSpeed(obj)
            % Take care of the possible infinite value for the speed
            obj.Config.placemaps.criteria_speed_cm_per_second_maximum = eval(obj.Config.placemaps.criteria_speed_cm_per_second_maximum);
            if obj.Config.placemaps.criteria_speed_cm_per_second_maximum < 0
                error('The config value placemaps.criteria_speed_cm_per_second_maximum must be >= 0, but is %f.', obj.Config.placemaps.criteria_speed_cm_per_second_maximum);
            end
            if obj.Config.placemaps.criteria_speed_cm_per_second_maximum < obj.Config.placemaps.criteria_speed_cm_per_second_minimum
                error('The config value placemaps.criteria_speed_cm_per_second_maximum (%f) must be greater than the minimum (%f).', ...
                    obj.Config.placemaps.criteria_speed_cm_per_second_maximum, obj.Config.placemaps.criteria_speed_cm_per_second_minimum);
            end
        end
        
    end % methods
    
    methods (Access = private)
        
        function taskFound = isValidTrialTask(obj, task)
            taskFound = MLPipeline.isValidTask(obj.availableTrialTasks, task);
        end
        
        function taskFound = isValidSessionTask(obj, task)
            taskFound = MLPipeline.isValidTask(obj.availableSessionTasks, task);
        end
        
        function taskFound = isValidExperimentTask(obj, task)
            taskFound = MLPipeline.isValidTask(obj.availableExperimentTasks, task);
        end
        
    end
    
    methods(Static)
        function taskFound = isValidTask( availableTasks, task )
           taskFound =  isKey(availableTasks, task);           
        end   
    end % methods
end % classdef
