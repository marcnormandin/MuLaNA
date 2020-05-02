classdef MLTetrodePipeline < MLPipeline
    properties
        pipelineConfigFilename = '';
        experimentDescriptionFilename = '';
        
        recordingsParentFolder = '';
        analysisParentFolder = '';
        config = '';
        
        % Kernel used to smooth the placemaps
        smoothingKernel = [];
        smoothingKernelSquare = [];
    end % properties
    
    methods
        function obj = MLTetrodePipeline(pipelineConfigFilename, recordingsParentFolder,  analysisParentFolder)
            obj.pipelineConfigFilename = pipelineConfigFilename;
            obj.recordingsParentFolder = recordingsParentFolder;
            obj.analysisParentFolder = analysisParentFolder;
            
            % Read in the pipeline configuration file
            if ~isfile( pipelineConfigFilename )
                error('The pipeline configuration file (%s) does not exist.', pipelineConfigFilename);
            end
            try 
                obj.config = jsondecode( fileread(pipelineConfigFilename) );
            catch ME
                error('Error encountered while reading pipeline configuration from (%s): %s', pipelineConfigFilename, ME.identifier)
            end
            
            % Read in the experiment file
            obj.experimentDescriptionFilename = fullfile(obj.recordingsParentFolder, 'experiment_description.json');
            if ~isfile( obj.experimentDescriptionFilename )
                error('Error! The file (%s) does not exist! How do you expect me to work?!', obj.experimentDescriptionFilename);
            end

            
            % Create the experiment structure
            obj.experiment = obj.mltp_create_session_folders( obj.recordingsParentFolder, obj.analysisParentFolder, obj.experimentDescriptionFilename );
            
            
            % Construct the kernel. Make sure that it is valid.
            % The kernel sizes must be odd so that they are symmetric
            if mod(obj.config.placemaps.smoothingKernelGaussianSize_cm,2) ~= 1
                error('The config value placemaps.smoothingKernelGaussianSize_cm must be odd, but it is %d.', obj.config.placemaps.smoothingKernelGaussianSize_cm);
            end
            obj.smoothingKernel = fspecial('gaussian', obj.config.placemaps.smoothingKernelGaussianSize_cm / obj.config.placemaps.cm_per_bin, obj.config.placemaps.smoothingKernelGaussianSigma_cm / obj.config.placemaps.cm_per_bin);
            obj.smoothingKernel = obj.smoothingKernel ./ max(obj.smoothingKernel(:)); % Isabel wants this like the other
            
            % Take care of the possible infinite value for the speed
            obj.config.placemaps.criteria_speed_cm_per_second_maximum = eval(obj.config.placemaps.criteria_speed_cm_per_second_maximum);
            if obj.config.placemaps.criteria_speed_cm_per_second_maximum < 0
                error('The config value placemaps.criteria_speed_cm_per_second_maximum must be >= 0, but is %f.', obj.config.placemaps.criteria_speed_cm_per_second_maximum);
            end
            if obj.config.placemaps.criteria_speed_cm_per_second_maximum < obj.config.placemaps.criteria_speed_cm_per_second_minimum
                error('The config value placemaps.criteria_speed_cm_per_second_maximum (%f) must be greater than the minimum (%f).', ...
                    obj.config.placemaps.criteria_speed_cm_per_second_maximum, obj.config.placemaps.criteria_speed_cm_per_second_minimum);
            end
            

            
            % These should go through a registration function to allow for
            % checking of duplicates
            obj.availablePerSessionTasks('nvt_split_into_trial_nvt') = @obj.mltp_nvt_split_into_trial_nvt;
            obj.availablePerSessionTasks('trial_nvt_to_trial_fnvt') = @obj.mltp_trial_nvt_to_trial_fnvt;
            obj.availablePerSessionTasks('user_define_trial_arenaroi') = @obj.mltp_user_define_trial_arenaroi;
            obj.availablePerSessionTasks('make_trial_position_plots_raw') = @obj.mltp_make_trial_position_plots_raw;
            obj.availablePerSessionTasks('make_trial_position_plots_fixed') = @obj.mltp_make_trial_position_plots_fixed;
            obj.availablePerSessionTasks('make_session_orientation_plot_unaligned') = @obj.mltp_make_session_orientation_plot_unaligned;
            obj.availablePerSessionTasks('make_session_orientation_plot_aligned') = @obj.mltp_make_session_orientation_plot_aligned;
            
            obj.availablePerSessionTasks('trial_fnvt_to_trial_can_movement') = @obj.mltp_trial_fnvt_to_trial_can_movement;

            obj.availablePerSessionTasks('tfiles_to_singleunits') = @obj.mltp_tfiles_to_singleunits;
            obj.availablePerSessionTasks('compute_singleunit_placemap_data') = @obj.mltp_compute_singleunit_placemap_data;
            obj.availablePerSessionTasks('compute_singleunit_placemap_data_shrunk') = @obj.mltp_compute_singleunit_placemap_data_shrunk;
            obj.availablePerSessionTasks('plot_singleunit_placemap_data') = @obj.mltp_plot_singleunit_placemap_data;
            
  
            % Best fit orientations for 0, 90, 180, 270
            obj.availablePerSessionTasks('compute_bfo_90_ac') = @obj.mltp_compute_bfo_90_ac;
            obj.availablePerSessionTasks('compute_bfo_90_wc') = @obj.mltp_compute_bfo_90_wc;
            obj.availablePerSessionTasks('compute_bfo_90_ac_per_cell') = @obj.mltp_compute_bfo_90_ac_per_cell;
            obj.availablePerExperimentTasks('plot_bfo_90_wc') = @obj.mltp_plot_bfo_90_wc;
            obj.availablePerExperimentTasks('plot_bfo_90_ac') = @obj.mltp_plot_bfo_90_ac;
            obj.availablePerSessionTasks('plot_bfo_90_ac_per_cell') = @obj.mltp_plot_bfo_90_ac_per_cell;
            obj.availablePerExperimentTasks('plot_bfo_90_averaged_across_sessions') = @obj.mltp_plot_bfo_90_averaged_across_sessions;   
            
            obj.availablePerSessionTasks('compute_best_fit_orientations_0_180_per_cell') = @obj.mltp_compute_best_fit_orientations_0_180_per_cell;
            obj.availablePerSessionTasks('plot_across_within_0_180_similarity') = @obj.mltp_plot_across_within_0_180_similarity;
            obj.availablePerSessionTasks('make_pfstats_excel') = @obj.mltp_make_pfstats_excel;
            
            obj.availablePerSessionTasks('plot_movement') = @obj.mltp_plot_movement;
            
            obj.availablePerSessionTasks('plot_nlx_mclust_plot_spikes_for_checking_bits') = @obj.mltp_nlx_mclust_plot_spikes_for_checking_bits;
            
            obj.availablePerExperimentTasks('plot_rate_difference_matrices') = @obj.mltp_plot_rate_difference_matrices;

            
        end % function
        
        [experiment] = mltp_create_session_folders( obj, recordingsParentFolder, analysisParentFolder, experimentDescriptionFilename );
        
        mltp_nvt_split_into_trial_nvt(obj, session);
        mltp_trial_nvt_to_trial_fnvt(obj, session);
        mltp_trial_fnvt_to_trial_can_movement(obj, session);
        mltp_tfiles_to_singleunits(obj, session);

        mltp_compute_singleunit_placemap_data(obj, session);
        mltp_compute_singleunit_placemap_data_shrunk(obj, session);
        mltp_plot_singleunit_placemap_data(obj, session);

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
        mltp_plot_rate_difference_matrices(obj);
        
        mltp_nlx_mclust_plot_spikes_for_checking_bits(obj, session);
        
        % new
        mltp_plot_movement(obj, session);
         
        function [arena] = getArena(obj)
            arena = obj.experiment.info.arena;
        end % function
        
    end % methods
end % classdef
