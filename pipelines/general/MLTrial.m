classdef MLTrial < MLTrialInterface
    %MLTrial An implementation for trial interface
    %   An implementation for a trial interface
    properties (SetAccess=private, GetAccess = protected)
        Name
        SliceId
        TrialId
        ContextId
        Digs
        HasDigs
        IsEnabled
        
        TrialDirectory
        AnalysisDirectory
        
        DateString
        TimeString
    end % properties
    
    methods
        function obj = MLTrial(name, sliceId, trialId, contextId, hasDigs, digs, isEnabled, ...
                trialDirectory, analysisDirectory, dateString, timeString)
           obj.Name = name;
           obj.TrialId = trialId;
           obj.SliceId = sliceId;
           obj.ContextId = contextId;
           obj.HasDigs = hasDigs;
           obj.Digs = digs;
           obj.IsEnabled = isEnabled;
           obj.TrialDirectory = trialDirectory;
           obj.AnalysisDirectory = analysisDirectory;
           obj.DateString = dateString;
           obj.TimeString = timeString;
        end
        
        function [s] = getName(obj)
            s = obj.Name;
        end
        
        function [id] = getSliceId(obj)
            id = obj.SliceId;
        end
        
        function [id] = getTrialId(obj) % id of this trial
            id = obj.TrialId;
        end
        
        function [id] = getContextId(obj)
            id = obj.ContextId;
        end
        
        function [digs] = getDigs(obj)
            digs = obj.Digs;
        end
        
        function [dig] = getDig(obj) % return only the first dig
            dig = obj.Digs{1};
        end
        
        function [b] = hasDigs(obj)
            b = obj.HasDigs;
        end
        
        function [b] = isEnabled(obj)
            b = obj.IsEnabled;
        end
        
        function [s] = getTrialDirectory(obj)
            s = obj.TrialDirectory;
        end
        
        function [s] = getAnalysisDirectory(obj)
            s = obj.AnalysisDirectory;
        end
        
        function [s] = getDateString(obj)
            s = obj.DateString;
        end
        
        function [s] = getTimeString(obj)
            s = obj.TimeString;
        end
    end
end
