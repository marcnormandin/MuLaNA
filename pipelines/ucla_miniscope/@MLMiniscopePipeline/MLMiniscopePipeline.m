classdef MLMiniscopePipeline < MLPipeline
    %MLMiniscopePipeline Miniscope pipeline
    %   A pipeline for the analysis of data from the UCLA Miniscope
    
    properties
        CnmfeOptions
        SpatialFootprintTrainedModel
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
            
            sfpTrainedModelFilename = obj.Config.sfp_trained_model_filename;
            if isfile(sfpTrainedModelFilename)
                tmp = load(sfpTrainedModelFilename, 'trainedModel');
                obj.SpatialFootprintTrainedModel = tmp.trainedModel;
            else
                warning('config.sfp_trained_model_filename refers to a nonexistent file (%s). cannot load model.', sfpTrainedModelFilename);
                obj.SpatialFootprintTrainedModel = [];
            end
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
            obj.registerTrialTask('compute_sfp_celllike', @obj.compute_sfp_celllike);
            
            obj.registerSessionTask('create_sfp_celllike_database', @mlgp_create_sfp_celllike_database);
            
            obj.registerTrialTask('compute_placemaps', @obj.compute_placemaps);
            obj.registerTrialTask('compute_placemaps_shrunk', @obj.compute_placemaps_shrunk);
            obj.registerTrialTask('plot_placemaps', @obj.plot_placemaps);
            
            %obj.registerTrialTask('compute_trace_placemaps', @obj.compute_trace_placemaps);

            obj.registerTrialTask('compute_smoothed_behaviour', @obj.compute_smoothed_behaviour);
            obj.registerTrialTask('compute_mcmappy', @obj.compute_mcmappy);
            obj.registerTrialTask('compute_mcmappy_shrunk', @obj.compute_mcmappy_shrunk);
            obj.registerSessionTask('create_mcmappy_database', @mlgp_create_mcmappy_database);
            obj.registerSessionTask('create_mcmappy_shrunk_database', @mlgp_create_mcmappy_shrunk_database);
            obj.registerSessionTask('create_climerics_database', @mlgp_create_climerics_database);

            obj.registerSessionTask('create_climerics_matrix_average', @create_climerics_matrix_average);
            obj.registerSessionTask('plot_and_save_cellreg_placemaps', @plot_and_save_cellreg_placemaps);
            
            obj.registerSessionTask('compute_placemaps_inclusion', @mlgp_compute_placemaps_inclusion);
            
            
            % DONT USE THIS.. OLD
%             obj.registerSessionTask('create_placemap_database', @mlgp_create_placemap_database);
%             obj.registerSessionTask('create_placemap_shrunk_database', @mlgp_create_placemap_shrunk_database);
            
            obj.registerSessionTask('compute_bfo_percell_90', @mlgp_compute_bfo_percell_90);
            obj.registerSessionTask('compute_bfo_percell_180', @mlgp_compute_bfo_percell_180);
            
            obj.registerSessionTask('compute_average_ratemap_difference_matrix', @compute_average_ratemap_difference_matrix);
            
            obj.registerSessionTask('compute_peak_difference_matrix', @compute_peak_difference_matrix);

            
            
            obj.registerSessionTask('compute_fluorescence_rate_scatterplots', @compute_fluorescence_rate_scatterplots);


            obj.registerSessionTask('compute_popvectors_dotproduct_cumulative', @compute_popvectors_dotproduct_cumulative);


            
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
        
%         checkDataIntegrity( obj, session, trial );
%         camerasdat_create( obj, session, trial );
%         behavcam_referenceframe_create( obj, session, trial );
%         behavcam_roi_create( obj, session, trial );
%         
%         convert_dlc_to_mlbehaviourtrack_per_trial( obj, session, trial );
%         
%         scopecam_alignvideo( obj, session, trial );
%         scopecam_cnmfe_run( obj, session, trial );
%         cnfme_spatial_footprints_save_to_cellreg(obj, session, trial);
%         cnmfe_to_neuron( obj, session, trial );
%         
%         compute_placemaps(obj, session, trial);
%         compute_placemaps_shrunk(obj, session, trial);
%         plot_placemaps(obj, session, trial);

    end % methods
end % classdef

