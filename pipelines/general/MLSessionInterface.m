classdef MLSessionInterface < handle
    % MLSessionInterface Interface for a session
    %   An interface for an experiment session
        
    methods (Abstract)
        getSessionRecord(obj);
        
        getName(obj)
        getDate(obj)
        
        getNumTrials(obj)
                
        % Return the trial by its id
        getTrial(obj, trialId )
        
        % Return the trial by its order number
        getTrialByOrder(obj, iTrial)
        
        % Returns a list of all valid trial ids for use with 
        % getTrial(obj, trialId)
        getTrialIds( obj );
        
        getSessionDirectory(obj)
        getAnalysisDirectory(obj)
    end
end
