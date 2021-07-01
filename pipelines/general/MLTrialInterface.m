classdef MLTrialInterface < handle
    %MLTrialInterface An interface for a session's trial
    %   An interface for a session's trial
        
    methods (Abstract)
        getName(obj)
        getSliceId(obj) % id of this trial
        getTrialId(obj)
        getContextId(obj)        

        getDigs(obj) % return 1 or more digs
        getDig(obj) % return only the first dig
        hasDigs(obj) 
        
        isEnabled(obj) % should the trial be used or not
        
        getTrialDirectory(obj)
        getAnalysisDirectory(obj)
        
        getDateString(obj);
        getTimeString(obj);
        
%         getRecordingDirectory(obj) % input for the analysis
%         getAnalysisDirectory(obj) % output for the analysis
%         
%         getNumUnits(obj)
%         getUnitNum(obj, iUnit)
    end
end
