classdef MLSession < MLSessionInterface
    % MLSession Implementation for a session
    %   An implementation for an experiment session
    properties (SetAccess=private, GetAccess = protected)
        Name
        Date
        Trials
        
        SessionDirectory
        AnalysisDirectory
    end % properties
    
    methods
        function obj = MLSession(...
                name, date, trials, ...
                sessionDirectory, analysisDirectory)
            
            obj.Name = name;
            obj.Date = date;
            obj.Trials = trials;
            obj.SessionDirectory = sessionDirectory;
            obj.AnalysisDirectory = analysisDirectory;
            
            if ~exist(obj.AnalysisDirectory, 'dir')
                mkdir(obj.AnalysisDirectory);
            end
        end % function
    end % methods
    
    methods
        function [s] = getName(obj)
            s = obj.Name;
        end
        
        function [s] = getDate(obj)
            s = obj.Date;
        end
        
        function [indices] = getTrialIndicesToUse(obj)
           N = length(obj.Trials);
           indices = [];
           for n = 1:N
               t = obj.getTrial(n);
               if t.isEnabled()
                   indices(end+1) = n;
               end
           end
        end
        
        function [n] = getNumTrialsToUse(obj)
            n = length(obj.getTrialIndicesToUse());
        end
        
        function [n] = getNumTrials(obj)
            n = length(obj.Trials);
        end
        
        function [t] = getTrial( obj, iTrial )
            if iTrial < 1 || iTrial > obj.getNumTrials()
                error('Invalid trial id (%d). Only sessions 1 to %d are available.', iTrial, obj.getNumTrials());
            end
            
            t = obj.Trials(iTrial);
        end
        
        function [t] = getTrialToUse( obj, iTrial )
            if iTrial < 1 || iTrial > obj.getNumTrialsToUse()
                error('Invalid trial id (%d). Only sessions 1 to %d are available.', iTrial, obj.getNumTrialsToUse());
            end
            
            ti = obj.getTrialIndicesToUse();
            
            t = obj.Trials(ti(iTrial));
        end
        
        function [s] = getSessionDirectory(obj)
            s = obj.SessionDirectory;
        end
        
        function [s] = getAnalysisDirectory(obj)
            s = obj.AnalysisDirectory;
        end
        
    end % methods
end
