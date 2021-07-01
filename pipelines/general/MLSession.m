classdef MLSession < MLSessionInterface
    % MLSession Implementation for a session
    %   An implementation for an experiment session
    properties (SetAccess=private, GetAccess = protected)
        Config
        
        SessionRecord
        Name
        Date
        Trials
        
        SessionDirectory
        AnalysisDirectory
    end % properties
    
    methods
        function obj = MLSession(...
                config, ...
                sessionRecord, ...
                name, date, trials, ...
                sessionDirectory, analysisDirectory)
            
            obj.Config = config;
            obj.SessionRecord = sessionRecord;
            obj.Name = name;
            obj.Date = date;
            obj.Trials = trials;
            obj.SessionDirectory = sessionDirectory;
            obj.AnalysisDirectory = analysisDirectory;
            
            if ~exist(obj.AnalysisDirectory, 'dir')
                fprintf('Making directory (%s)...', obj.AnalysisDirectory);
                mkdir(obj.AnalysisDirectory);
                fprintf('done.\n');
            end
        end % function
    end % methods
    
    methods
        function [sr] = getSessionRecord(obj)
            sr = obj.SessionRecord;
        end
        
        function [s] = getName(obj)
            s = obj.Name;
        end
        
        function [s] = getDate(obj)
            s = obj.Date;
        end
        
        function [n] = getNumTrials(obj)
            n = length(obj.Trials);
        end
        
        function [trial] = getTrial( obj, trialId )
            % Make a list of the trial ids
            trialIds = zeros(obj.getNumTrials(), 1);
            for iTrial = 1:obj.getNumTrials()
                t = obj.Trials(iTrial);
                trialIds(iTrial) = t.getTrialId();
            end
            
            ind = find(trialIds == trialId);
            trial = [];
            if ~isempty(ind)
                trial = obj.Trials(ind);
            else
                trial = [];
                warning('Trial %d not found.\n', trialId);
            end
        end
        
        % This is mostly used when processing trials in loops
        function [t] = getTrialByOrder( obj, iTrial )
            if iTrial < 1 || iTrial > obj.getNumTrials()
                error('Invalid trial order (%d). Only order 1 to %d are available.', iTrial, obj.getNumTrials());
            end
            
            t = obj.Trials(iTrial);
        end
        
        function [tids] = getTrialIds( obj )
            % Returns an array of valid trial ids for use with
            % getTrial(obj, trialId)
            tids = zeros(1, obj.getNumTrials());
            for iTrial = 1:obj.getNumTrials()
                trial = obj.getTrialByOrder(iTrial);
                tids(iTrial) = trial.getTrialId();
            end
        end
        
%         function [t] = getTrialToUse( obj, iTrial )
%             if iTrial < 1 || iTrial > obj.getNumTrialsToUse()
%                 error('Invalid trial id (%d). Only sessions 1 to %d are available.', iTrial, obj.getNumTrialsToUse());
%             end
%             
%             ti = obj.getTrialIndicesToUse();
%             
%             t = obj.Trials(ti(iTrial));
%         end
        
        function [s] = getSessionDirectory(obj)
            s = obj.SessionDirectory;
        end
        
        function [s] = getAnalysisDirectory(obj)
            s = obj.AnalysisDirectory;
        end
        
    end % methods
end
