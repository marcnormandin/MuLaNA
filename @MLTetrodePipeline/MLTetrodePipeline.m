classdef MLTetrodePipeline < MLPipeline2
    properties
        
    end % properties
    
    methods
        function obj = MLTetrodePipeline(config, recordingsParentFolder,  analysisParentFolder)
            obj@MLPipeline2(config, recordingsParentFolder,  analysisParentFolder);
            obj.initialize();
            
            obj.registerAvailableTasks();
            
        end
            
    end
    
    methods (Access = private)
        function initialize(obj)
            % nothing to do
        end % function
        
        function registerAvailableTasks(obj)
            % These should go through a registration function to allow for
            % checking of duplicates
            obj.registerSessionTask('nvt_split_into_trial_nvt', @obj.mltp_nvt_split_into_trial_nvt);
            obj.registerSessionTask('trial_nvt_to_trial_fnvt', @obj.mltp_trial_nvt_to_trial_fnvt);
            obj.registerSessionTask('user_define_trial_arenaroi', @obj.mltp_user_define_trial_arenaroi);
            obj.registerSessionTask('make_trial_position_plots_raw', @obj.mltp_make_trial_position_plots_raw);
            obj.registerSessionTask('make_trial_position_plots_fixed', @obj.mltp_make_trial_position_plots_fixed);
            obj.registerSessionTask('make_session_orientation_plot_unaligned', @obj.mltp_make_session_orientation_plot_unaligned);
            obj.registerSessionTask('make_session_orientation_plot_aligned', @obj.mltp_make_session_orientation_plot_aligned);
            
            obj.registerSessionTask('trial_fnvt_to_trial_can_movement', @obj.mltp_trial_fnvt_to_trial_can_movement);

            obj.registerSessionTask('tfiles_to_singleunits', @obj.mltp_tfiles_to_singleunits);
            obj.registerSessionTask('compute_singleunit_placemap_data', @obj.mltp_compute_singleunit_placemap_data);
            obj.registerSessionTask('compute_singleunit_placemap_data_shrunk', @obj.mltp_compute_singleunit_placemap_data_shrunk);
            obj.registerSessionTask('plot_singleunit_placemap_data', @obj.mltp_plot_singleunit_placemap_data);
            
            obj.registerSessionTask('plot_placemaps', @obj.mltp_plot_placemaps);
  
            % Best fit orientations for 0, 90, 180, 270
            obj.registerSessionTask('compute_bfo_90_ac', @obj.mltp_compute_bfo_90_ac);
            obj.registerSessionTask('compute_bfo_90_wc', @obj.mltp_compute_bfo_90_wc);
            obj.registerSessionTask('compute_bfo_90_ac_per_cell', @obj.mltp_compute_bfo_90_ac_per_cell);
            obj.registerExperimentTask('plot_bfo_90_wc', @obj.mltp_plot_bfo_90_wc);
            obj.registerExperimentTask('plot_bfo_90_ac', @obj.mltp_plot_bfo_90_ac);
            obj.registerSessionTask('plot_bfo_90_ac_per_cell', @obj.mltp_plot_bfo_90_ac_per_cell);
            obj.registerExperimentTask('plot_bfo_90_averaged_across_sessions', @obj.mltp_plot_bfo_90_averaged_across_sessions);   
            
            obj.registerSessionTask('compute_best_fit_orientations_0_180_per_cell', @obj.mltp_compute_best_fit_orientations_0_180_per_cell);
            obj.registerSessionTask('plot_across_within_0_180_similarity', @obj.mltp_plot_across_within_0_180_similarity);
            obj.registerSessionTask('make_pfstats_excel', @obj.mltp_make_pfstats_excel);
            
            obj.registerSessionTask('plot_movement', @obj.mltp_plot_movement);
            
            obj.registerSessionTask('plot_nlx_mclust_plot_spikes_for_checking_bits', @obj.mltp_nlx_mclust_plot_spikes_for_checking_bits);
            
            obj.registerSessionTask('plot_rate_difference_matrices', @obj.mltp_plot_rate_difference_matrices);
            obj.registerExperimentTask('plot_rate_difference_matrix_average_days', @obj.mltp_plot_rate_difference_matrix_average_days);
            
            obj.registerSessionTask('plot_behaviour_averaged_placemaps', @obj.mltp_plot_behaviour_averaged_placemaps);
            obj.registerSessionTask('plot_behaviour_averaged_placemaps_contexts', @obj.mltp_plot_behaviour_averaged_placemaps_contexts);
            
        end % function
        
    end % methods private
        

    methods
        mltp_nvt_split_into_trial_nvt(obj, session);
        mltp_trial_nvt_to_trial_fnvt(obj, session);
        mltp_trial_fnvt_to_trial_can_movement(obj, session);
        mltp_tfiles_to_singleunits(obj, session);

        mltp_compute_singleunit_placemap_data(obj, session);
        mltp_compute_singleunit_placemap_data_shrunk(obj, session);
        mltp_plot_singleunit_placemap_data(obj, session);
        mltp_plot_placemaps(obj, session);
        
        mltp_make_trial_position_plots_raw(obj, session);
        mltp_make_trial_position_plots_fixed(obj, session);
        mltp_user_define_trial_arenaroi(obj, session);
        

        
        

        
        % 0, 90, 180, 270
        mltp_compute_bfo_90_ac(obj, session);
        mltp_compute_bfo_90_wc(obj, session);
        mltp_compute_bfo_90_ac_per_cell(obj, session);
        mltp_plot_bfo_90_ac(obj) % all contexts
        mltp_plot_bfo_90_wc(obj); % within contexts
        mltp_plot_bfo_90_ac_per_cell(obj, session);
        mltp_plot_bfo_90_averaged_across_sessions(obj);

        
        % 0, 180
        mltp_compute_best_fit_orientations_0_180_per_cell(obj, session);
        mltp_plot_best_fit_orientations_0_180_per_cell(obj, session);
        mltp_plot_across_within_0_180_similarity(obj, session);      
        
        mltp_make_session_orientation_plot_unaligned(obj, session);
        mltp_make_session_orientation_plot_aligned(obj, session);
        
        



        mltp_make_pfstats_excel(obj, session);
        mltp_plot_rate_difference_matrices(obj, session);
        mltp_plot_rate_difference_matrix_average_days(obj);
        
        
        mltp_nlx_mclust_plot_spikes_for_checking_bits(obj, session);
        
        mltp_plot_behaviour_averaged_placemaps(obj, session);
        mltp_plot_behaviour_averaged_placemaps_contexts(obj, session);
        
        % new
        mltp_plot_movement(obj, session);
         
        function [arena] = getArena(obj)
            arena = obj.Experiment.getArenaGeometry();
        end % function
        
    end % methods
end % classdef
