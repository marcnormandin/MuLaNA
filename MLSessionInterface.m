classdef MLSessionInterface < handle
    % MLSessionInterface Interface for a session
    %   An interface for an experiment session
        
    methods (Abstract)
        getName(obj)
        getDate(obj)
        getTrialIndicesToUse(obj)
        getNumTrials(obj)
        getNumTrialsToUse(obj)
        getTrial(obj, iTrial )
        
        getSessionDirectory(obj)
        getAnalysisDirectory(obj)
    end
end
