classdef MLPipeline < handle
    
    properties
        experiment;
        
        verbose = true;
    end
    
    properties %(Access = protected)
        availablePerTrialTasks = containers.Map('KeyType', 'char', 'ValueType', 'any');
        availablePerSessionTasks = containers.Map('KeyType', 'char', 'ValueType', 'any');
        availablePerExperimentTasks = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end
    
    methods
        function printAvailableTasks(obj)
            fprintf('Per trial tasks:\n');
            if obj.availablePerTrialTasks.length == 0
                fprintf('\t none\n');
            else
                at = obj.availablePerTrialTasks;
                k = at.keys;
                for i = 1:at.length
                    fprintf('\t%s\n',k{i})
                end
            end
            fprintf('\n');
            
            fprintf('Per session tasks:\n');
            if obj.availablePerSessionTasks.length == 0
                fprintf('\t none\n');
            else
                at = obj.availablePerSessionTasks;
                k = at.keys;
                for i = 1:at.length
                    fprintf('\t%s\n',k{i})
                end
            end
            fprintf('\n');
            
            fprintf('Per experiment tasks:\n');
            if obj.availablePerExperimentTasks.length == 0
                fprintf('\t none\n');
            else
                at = obj.availablePerExperimentTasks;
                k = at.keys;
                for i = 1:at.length
                    fprintf('\t%s\n',k{i})
                end
            end
        end
        
        function taskReport = executeTask_AllTrials( obj, task )
            if obj.isValidPerTrialTask( task )
                % Setup a structure to record the results of the tasks
                taskReport.session = cell(obj.experiment.numSessions,1);
                taskReport.task = task;
                taskTic = tic;
                for iSession = 1:obj.experiment.numSessions
                    session = obj.getSessionByIndex(iSession);
                    taskReport.session{iSession}.trial = cell(session.numTrials,1);
                end
                
                % Execute the task
                for iSession = 1:obj.experiment.numSessions
                    session = obj.getSessionByIndex(iSession);
                    sessionTic = tic;
                    
                    for iTrial = 1:session.numTrials
                        if obj.verbose
                            fprintf('Pipeline task ( %s ) -> Processing session %d/%d ( %s ) trial %d/%d \n', task, ...
                                iSession, obj.experiment.numSessions, session.name, iTrial, session.numTrials );
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
        
        function executeExperimentTask(obj, task)
            if obj.isValidPerExperimentTask( task )
                % execute the task
                func = obj.availablePerExperimentTasks(task);
                func();
            end
        end
        
        function executePerSessionTask( obj, task )
            for iSession = 1:obj.experiment.numSessions
                obj.executePerSessionTaskByIndex(task, iSession);
            end
        end
        
        
        function executePerSessionTaskByIndex( obj, task, iSession )
            if obj.isValidPerSessionTask( task )

                session = obj.experiment.session{iSession};
                    
                if obj.verbose
                    fprintf('Pipeline task ( %s ) -> Processing session %d/%d ( %s )\n', task, ...
                        iSession, obj.experiment.numSessions, session.name );
                end
                
                % execute the task
                func = obj.availablePerSessionTasks(task);
                func(session);
            end
        end
        
        function executePerTrialTaskByIndex( obj, task, iSession, iTrial )
            if obj.isValidPerTrialTask( task )

                session = obj.getSessionByIndex(iSession);
                trial = obj.getTrialFromSessionByIndex(session, iTrial);
                
                % execute the trial task
            else
                error('Invalid trial task (%s).', task);
            end
        end
        
    end
    
    methods (Access = private)
        function taskFound = isValidPerTrialTask(obj, task)
            taskFound = obj.isValidTask(obj.availablePerTrialTasks, task);
        end
        
        function taskFound = isValidPerSessionTask(obj, task)
            taskFound = obj.isValidTask(obj.availablePerSessionTasks, task);
        end
        
        function taskFound = isValidPerExperimentTask(obj, task)
            taskFound = obj.isValidTask(obj.availablePerExperimentTasks, task);
        end
        
        function taskFound = isValidTask( obj, availableTasks, task )
           taskFound =  isKey(availableTasks, task);           
        end
        
        function session = getSessionByIndex(obj, iSession)
            numSessions = obj.experiment.numSessions;
            if iSession < 0 || iSession > numSessions
                error('Invalid session index (%d)')
            end
            session = obj.experiment.session{iSession};
        end
        
        function trial = getTrialFromSessionByIndex(obj, session, iTrial)
            numTrials = session.numTrials;
            if iTrial < 0 || iTrial > numTrials
                error('Invalid trial index');
            end
            trial = session.trial{iTrial};
        end
        
    end % methods
end % classdef
