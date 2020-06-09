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
        getTrialToUse(obj, iTrial)
        
        %getNumSingleUnits(obj);
        %getSingleUnit(obj, iUnit);
        
        getSessionDirectory(obj)
        getAnalysisDirectory(obj)
    end
end
