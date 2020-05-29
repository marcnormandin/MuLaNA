classdef MLPipeline2 < handle
    
    properties (SetAccess = protected, GetAccess = public)

        RecordingsParentFolder
        AnalysisParentFolder
        
        Config
        
        Experiment

        % Kernel used to smooth the placemaps
        SmoothingKernel
        
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
        function obj = MLPipeline2(config, recordingsParentFolder,  analysisParentFolder)
            obj.Verbose = config.verbose;
            
            obj.Config = config;
            obj.RecordingsParentFolder = recordingsParentFolder;
            obj.AnalysisParentFolder = analysisParentFolder;
            
            obj.Experiment = MLExperimentBuilder.buildFromJson(recordingsParentFolder, analysisParentFolder);

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
                func(session);
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
            
            obj.configSetupSmoothingKernel();
            
            obj.configValidateSpeed();
        end
        
        function configSetupSmoothingKernel(obj)
            % Construct the kernel. Make sure that it is valid.
            % The kernel sizes must be odd so that they are symmetric
            if mod(obj.Config.placemaps.smoothingKernelGaussianSize_cm,2) ~= 1
                error('The config value placemaps.smoothingKernelGaussianSize_cm must be odd, but it is %d.', obj.Config.placemaps.smoothingKernelGaussianSize_cm);
            end
            % Make sure that the size is odd so that gaussian peak is at
            % the central bin
            hsize = ceil(obj.Config.placemaps.smoothingKernelGaussianSize_cm / obj.Config.placemaps.cm_per_bin);
            if mod(hsize,2) ~= 1
                hsize = hsize + 1;
            end
            obj.SmoothingKernel = fspecial('gaussian', hsize, obj.Config.placemaps.smoothingKernelGaussianSigma_cm / obj.Config.placemaps.cm_per_bin);
            obj.SmoothingKernel = obj.SmoothingKernel ./ max(obj.SmoothingKernel(:)); % Isabel wants this like the other
             
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
            taskFound = MLPipeline2.isValidTask(obj.availableTrialTasks, task);
        end
        
        function taskFound = isValidSessionTask(obj, task)
            taskFound = MLPipeline2.isValidTask(obj.availableSessionTasks, task);
        end
        
        function taskFound = isValidExperimentTask(obj, task)
            taskFound = MLPipeline2.isValidTask(obj.availableExperimentTasks, task);
        end
        
    end
    
    methods(Static)
        function taskFound = isValidTask( availableTasks, task )
           taskFound =  isKey(availableTasks, task);           
        end   
    end % methods
end % classdef
