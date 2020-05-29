classdef MLMiniscopePipeline < MLPipeline2
    %MLMiniscopePipeline Miniscope pipeline
    %   A pipeline for the analysis of data from the UCLA Miniscope
    
    properties
        CnmfeOptions
    end % properties
    
    methods
        function obj = MLMiniscopePipeline(config, recordingsParentFolder,  analysisParentFolder)
            %MLMiniscopePipeline Construct an instance of this class
            obj@MLPipeline2(config, recordingsParentFolder,  analysisParentFolder)
            
            obj.initialize();
            
            obj.registerAvailableTasks();
        end
        
    end % methods
    
    methods (Access = private)
        
        function initialize(obj)
            obj.CnmfeOptions = men_cnmfe_options_create('framesPerSecond', 30, 'verbose', obj.isVerbose());
        end % function

        function obj = registerAvailableTasks(obj)
            obj.registerTrialTask('check_data_integrity', @obj.checkDataIntegrity);

            obj.registerTrialTask('camerasdat_create', @obj.camerasdat_create);
            obj.registerTrialTask('behavcam_referenceframe_create', @obj.behavcam_referenceframe_create);
            obj.registerTrialTask('behavcam_roi_create', @obj.behavcam_roi_create);
            
            obj.registerTrialTask('convert_dlc_to_mlbehaviourtrack', @obj.convert_dlc_to_mlbehaviourtrack_per_trial);
            
            obj.registerTrialTask('scopecam_alignvideo', @obj.scopecam_alignvideo);
            obj.registerTrialTask('scopecam_cnmfe_run', @obj.scopecam_cnmfe_run);
            obj.registerTrialTask('cnfme_spatial_footprints_save_to_cellreg', @obj.cnfme_spatial_footprints_save_to_cellreg);
            obj.registerTrialTask('cnmfe_to_neuron', @obj.cnmfe_to_neuron);
            
            obj.registerTrialTask('plot_and_save_placemaps', @obj.plot_and_save_placemaps);
        end % function
        
    end % methods private
        
        
    methods
        
        %
        % FUNCTION SIGNATURES
        %
        
        checkDataIntegrity( obj, session, trial );
        camerasdat_create( obj, session, trial );
        behavcam_referenceframe_create( obj, session, trial );
        behavcam_roi_create( obj, session, trial );
        
        convert_dlc_to_mlbehaviourtrack_per_trial( obj, session, trial );
        
        scopecam_alignvideo( obj, session, trial );
        scopecam_cnmfe_run( obj, session, trial );
        cnfme_spatial_footprints_save_to_cellreg(obj, session, trial);
        cnmfe_to_neuron( obj, session, trial );
        
        plot_and_save_placemaps(obj, session, trial);
        
    end % methods
end % classdef

