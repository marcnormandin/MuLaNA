classdef MLSession < handle
    properties
        verbose = true;
        
        name;
        
        dataFolder;
        resultsFolder;
        
        % Trials that will be processed by the tasks
        trialIndexList;
        numTrials;
        
        % Trials that have data (some of which will not be used)
        numTrialsRecorded;
        trialRecordedList;
    end
    
    methods
        
    end % methods
    
end % classdef
