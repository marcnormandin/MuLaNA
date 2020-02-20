classdef MLTetrodeSession < MLSession
    properties
        CONFIG_NVT_FILENAME = 'VT1.nvt';
        CONFIG_NVT_FILE_TRIAL_SEPARATION_THRESHOLD_S = 10;
    end
    
    methods
        function obj = MLTetrodeSession()
            
        end
        
        split_into_trials(obj)
        
    end % methods
    
end % classdef
