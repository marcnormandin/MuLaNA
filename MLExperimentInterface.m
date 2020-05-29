classdef MLExperimentInterface < handle
    %MLExperimentInterface Interface to an experiment
    %   An interface to an experiment
    
    methods (Abstract)
        getAnimalName(obj)
        getImagingRegion(obj)
        getExperimentName(obj)
        getArenaGeometry(obj)
        getNumSessions(obj)
        getSession( obj, iSession )
        
        % Directories for input and output
        getSessionsParentDirectory()
        getAnalysisParentDirectory()
    end % methods
    
end % classdef
