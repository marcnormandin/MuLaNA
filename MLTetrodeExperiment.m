classdef MLTetrodeExperiment < MLExperiment
    %MLTetrodeExperiment A tetrode experiment
    %   Represents a tetrode experiment
    
    properties
        TFileBits
        NvtFileTrialSeparationThresholdS
        NvtFilename
    end
    
    methods
        
        function obj = MLTetrodeExperiment(...
                animalName, imagingRegion, experimentName, arenaGeometry, numContexts, sessions, ...
                sessionsParentDirectory, analysisParentDirectory, ...
                mclustTfileBits, nvtThreshold, nvtFilename)
            
            obj@MLExperiment(...
                animalName, imagingRegion, experimentName, arenaGeometry, numContexts, sessions, ...
                sessionsParentDirectory, analysisParentDirectory);
            
            obj.TFileBits = mclustTfileBits;
            obj.NvtFileTrialSeparationThresholdS = nvtThreshold;
            obj.NvtFilename = nvtFilename;
        end
        
        function [n] = getTFileBits(obj)
            n = obj.TFileBits;
        end
        
        function [n] = getNvtTrialSeparationThresholdS(obj)
           n = obj.NvtFileTrialSeparationThresholdS;
        end
        
        function [s] = getNvtFilename(obj)
            s = obj.NvtFilename;
        end
        
    end % methods
end % classdef

