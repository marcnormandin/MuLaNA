classdef MLExperiment < MLExperimentInterface
    %MLExperiment Implementation of the interface
    %   An implementation of the experiment interface
    
    properties (SetAccess=private, GetAccess = protected)
        AnimalName
        ImagingRegion
        ExperimentName
        ArenaGeometry
        NumContexts
        Sessions
        
        SessionsParentDirectory
        AnalysisParentDirectory
    end % properties
    
    methods
        function obj = MLExperiment( ...
                animalName, imagingRegion, experimentName, arenaGeometry, numContexts, sessions, ...
                sessionsParentDirectory, analysisParentDirectory)
            
            obj.AnimalName = animalName;
            obj.ImagingRegion = imagingRegion;
            obj.ExperimentName = experimentName;
            obj.ArenaGeometry = arenaGeometry;
            obj.NumContexts = numContexts;
            obj.Sessions = sessions;
            obj.SessionsParentDirectory = sessionsParentDirectory;
            obj.AnalysisParentDirectory = analysisParentDirectory;
        end % function
        
        
    end % methods
    
    methods
        function [s] = getAnimalName(obj)
            s = obj.AnimalName;
        end
        
        function [s] = getImagingRegion(obj)
            s = obj.ImagingRegion;
        end
        
        function [s] = getExperimentName(obj)
            s = obj.ExperimentName;
        end
        
        function [a] = getArenaGeometry(obj)
            a = obj.ArenaGeometry;
        end
        
        function [n] = getNumContexts(obj)
            n = obj.NumContexts;
        end
        
        function [n] = getNumSessions(obj)
            n = length(obj.Sessions);
        end
        
        function [s] = getSession( obj, iSession )
            if iSession < 1 || iSession > obj.getNumSessions()
                error('Invalid session id (%d). Only sessions 1 to %d are available.', iSession, obj.getNumSessions());
            end
            
            s = obj.Sessions(iSession);
        end
        
        function [s] = getSessionsParentDirectory(obj)
            s = obj.SessionsParentDirectory;
        end
        
        function [s] = getAnalysisParentDirectory(obj)
            s = obj.AnalysisParentDirectory;
        end
        
    end % methods
    
end % classdef

