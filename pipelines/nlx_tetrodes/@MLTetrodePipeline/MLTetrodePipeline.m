classdef MLTetrodePipeline < MLPipeline
    properties
        
    end % properties
    
    methods
        function obj = MLTetrodePipeline(config, recordingsParentFolder,  analysisParentFolder)
            obj@MLPipeline(config, recordingsParentFolder,  analysisParentFolder);
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
            obj.registerSessionTask('nvt_split_into_slice_nvt', @mltp_nvt_split_into_slice_nvt);
            obj.registerSessionTask('slice_nvt_to_slice_fnvt', @mltp_slice_nvt_to_slice_fnvt);
            obj.registerTrialTask('user_define_slice_arenaroi', @obj.mltp_user_define_slice_arenaroi);
            obj.registerSessionTask('user_define_session_arenaroi', @mltp_user_define_session_arenaroi);
            
            obj.registerSessionTask('make_trial_position_plots_raw', @mltp_make_trial_position_plots_raw);
            obj.registerSessionTask('make_trial_position_plots_fixed', @mltp_make_trial_position_plots_fixed);
            obj.registerSessionTask('make_session_orientation_plot_unaligned', @mltp_make_session_orientation_plot_unaligned);
            obj.registerSessionTask('make_session_orientation_plot_aligned', @mltp_make_session_orientation_plot_aligned);
            
            obj.registerSessionTask('slice_fnvt_to_slice_can_movement', @mltp_slice_fnvt_to_slice_can_movement);

            obj.registerSessionTask('tfiles_to_singleunits', @mltp_tfiles_to_singleunits);
            obj.registerSessionTask('compute_singleunit_placemap_data', @mltp_compute_singleunit_placemap_data);
            obj.registerSessionTask('compute_singleunit_placemap_data_shrunk', @mltp_compute_singleunit_placemap_data_shrunk);
            
            % Old version
            %obj.registerSessionTask('plot_singleunit_placemap_data', @obj.mltp_plot_singleunit_placemap_data);
            
            obj.registerSessionTask('plot_placemaps', @mltp_plot_placemaps);
            obj.registerSessionTask('plot_placemap_information_dists', @mltp_plot_placemap_information_dists);
            
            
            obj.registerSessionTask('make_pfstats_excel', @mltp_make_pfstats_excel);
            obj.registerSessionTask('plot_movement', @mltp_plot_movement);
            obj.registerSessionTask('plot_nlx_mclust_plot_spikes_for_checking_bits', @mltp_nlx_mclust_plot_spikes_for_checking_bits);
            
            obj.registerSessionTask('compute_best_match_rotations', @mltp_compute_best_match_rotation_rect);
            obj.registerExperimentTask('plot_best_match_rotations_rect_per_session', @obj.mltp_plot_best_match_rotations_rect_per_session);
            
            
            obj.registerSessionTask('plot_rate_difference_matrices', @mltp_plot_rate_difference_matrices);
            obj.registerExperimentTask('plot_rate_difference_matrix_average_days', @obj.mltp_plot_rate_difference_matrix_average_days);
            
            obj.registerSessionTask('plot_behaviour_averaged_placemaps', @mltp_plot_behaviour_averaged_placemaps);
            obj.registerSessionTask('plot_behaviour_averaged_placemaps_contexts', @mltp_plot_behaviour_averaged_placemaps_contexts);
            
            
            
  
            % Best fit orientations for 0, 90, 180, 270
%             obj.registerSessionTask('compute_bfo_90_ac', @obj.mltp_compute_bfo_90_ac);
%             obj.registerSessionTask('compute_bfo_90_wc', @obj.mltp_compute_bfo_90_wc);
%             obj.registerSessionTask('compute_bfo_90_ac_per_cell', @obj.mltp_compute_bfo_90_ac_per_cell);
%             obj.registerExperimentTask('plot_bfo_90_wc', @obj.mltp_plot_bfo_90_wc);
%             obj.registerExperimentTask('plot_bfo_90_ac', @obj.mltp_plot_bfo_90_ac);
%             obj.registerExperimentTask('plot_bfo_90_dc', @obj.mltp_plot_bfo_90_dc);



            obj.registerSessionTask('plot_bfo_90_ac_per_cell', @mltp_plot_bfo_90_ac_per_cell);
            obj.registerExperimentTask('plot_bfo_90_averaged_across_sessions', @obj.mltp_plot_bfo_90_averaged_across_sessions);   
            
            % New 
            obj.registerSessionTask('compute_bfo_90', @mltp_compute_bfo_90)
            obj.registerExperimentTask('compute_bfo_90_average', @obj.mltp_compute_bfo_90_average);
            obj.registerExperimentTask('plot_bfo_90_sessions', @obj.mltp_plot_bfo_90_sessions);
            obj.registerSessionTask('plot_bfo_90_session_grouped', @mltp_plot_bfo_90_session_grouped);
            
            % New placey
            obj.registerSessionTask('compute_bfo_90_placey', @mltp_compute_bfo_90_placey)
            obj.registerExperimentTask('compute_bfo_90_placey_average', @obj.mltp_compute_bfo_90_placey_average);
            obj.registerExperimentTask('plot_bfo_90_placey_sessions', @obj.mltp_plot_bfo_90_placey_sessions);
            obj.registerSessionTask('plot_bfo_90_placey_session_grouped', @mltp_plot_bfo_90_placey_session_grouped);
            
            % Best fit orientations 0, 180 degrees
            obj.registerSessionTask('compute_bfo_180_ac', @mltp_compute_bfo_180_ac);
            %obj.registerExperimentTask('plot_bfo_180_ac', @obj.mltp_plot_bfo_180_ac);
            obj.registerExperimentTask('compute_bfo_180_average', @obj.mltp_compute_bfo_180_average);
            obj.registerExperimentTask('plot_bfo_180_sessions', @obj.mltp_plot_bfo_180_sessions);
            obj.registerSessionTask('plot_bfo_180_session_grouped', @mltp_plot_bfo_180_session_grouped);

            obj.registerSessionTask('compute_bfo_180_ac_per_cell', @mltp_compute_bfo_180_ac_per_cell);
            obj.registerSessionTask('plot_bfo_180_ac_per_cell', @mltp_plot_bfo_180_ac_per_cell);
            
            obj.registerSessionTask('compute_bfo_180', @mltp_compute_bfo_180)
          
            obj.registerSessionTask('plot_across_within_0_180_similarity', @mltp_plot_across_within_0_180_similarity);

            
            obj.registerSessionTask('remove_invalid_t_files', @mltp_nlx_mclust_remove_invalid_t_files);
            

            
        end % function
        
    end % methods private
        

    methods
         
        function [arena] = getArena(obj)
            arena = obj.Experiment.getArenaGeometry();
        end % function
        
    end % methods
end % classdef
