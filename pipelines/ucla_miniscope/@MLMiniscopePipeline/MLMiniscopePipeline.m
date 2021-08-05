classdef MLMiniscopePipeline < MLPipeline
    %MLMiniscopePipeline Miniscope pipeline
    %   A pipeline for the analysis of data from the UCLA Miniscope
    
    properties
        CnmfeOptions
    end % properties
    
    methods
        function obj = MLMiniscopePipeline(config, recordingsParentFolder,  analysisParentFolder)
            %MLMiniscopePipeline Construct an instance of this class
            obj@MLPipeline(config, recordingsParentFolder,  analysisParentFolder)
            
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
            obj.registerTrialTask('compactify_sfp', @obj.compactify_sfp);
            
            
            
            
            obj.registerTrialTask('compute_placemaps', @obj.compute_placemaps);
            obj.registerTrialTask('compute_placemaps_shrunk', @obj.compute_placemaps_shrunk);
            obj.registerTrialTask('plot_placemaps', @obj.plot_placemaps);
            
            
            obj.registerSessionTask('create_placemap_database', @mlgp_create_placemap_database);
            obj.registerSessionTask('create_placemap_shrunk_database', @mlgp_create_placemap_shrunk_database);
            
            obj.registerSessionTask('compute_bfo_percell_90', @mlgp_compute_bfo_percell_90);
            obj.registerSessionTask('compute_bfo_percell_180', @mlgp_compute_bfo_percell_180);


            
            %obj.registerSessionTask('compute_bfo_90', @mlgp_compute_bfo_90);
%             obj.registerExperimentTask('compute_bfo_90_average', @mlgp_compute_bfo_90_average);
%             
%             obj.registerExperimentTask('plot_bfo_90_sessions', @mlgp_plot_bfo_90_sessions);
%             obj.registerSessionTask('plot_bfo_90_session_grouped', @mlgp_plot_bfo_90_session_grouped);
%             
%             obj.registerSessionTask('plot_cellreg_placemaps', @plot_cellreg_placemaps);
%             obj.registerSessionTask('plot_cellreg_spatialfootprints', @plot_cellreg_spatialfootprints);
%             
%             obj.registerSessionTask('compute_bfo_180', @mlgp_compute_bfo_180);
%             
%             obj.registerSessionTask('plot_cumulative_similarity', @mlgp_plot_cumulative_similarity);
            
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
        
        compute_placemaps(obj, session, trial);
        compute_placemaps_shrunk(obj, session, trial);
        plot_placemaps(obj, session, trial);

    end % methods
end % classdef

