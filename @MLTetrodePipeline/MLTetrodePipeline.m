classdef MLTetrodePipeline < MLPipeline
    properties
        pipelineConfigFilename = '';
        experimentDescriptionFilename = '';
        
        recordingsParentFolder = '';
        analysisParentFolder = '';
        config = '';
        
        % Kernel used to smooth the placemaps
        smoothingKernelRect = [];
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
            
            % Construct the kernel. Make sure that it is valid.
            % The kernel sizes must be odd so that they are symmetric
            if mod(obj.config.placemaps_rect.smoothingKernelGaussianSize,2) ~= 1
                error('The config value placemaps_rect.smoothingKernelGaussianSize must be odd, but it is %d.', obj.config.placemaps_rect.smoothingKernelGaussianSize);
            end
            obj.smoothingKernelRect = fspecial('gaussian', obj.config.placemaps_rect.smoothingKernelGaussianSize, obj.config.placemaps_rect.smoothingKernelGaussianSigma);
            obj.smoothingKernelRect = obj.smoothingKernelRect ./ max(obj.smoothingKernelRect(:)); % Isabel wants this like the other
            
            if mod(obj.config.placemaps_square.smoothingKernelGaussianSize,2) ~= 1
                error('The config value placemaps_square.smoothingKernelGaussianSize must be odd, but it is %d.', obj.config.placemaps_square.smoothingKernelGaussianSize);
            end
            obj.smoothingKernelSquare = fspecial('gaussian', obj.config.placemaps_square.smoothingKernelGaussianSize, obj.config.placemaps_square.smoothingKernelGaussianSigma);
            obj.smoothingKernelSquare = obj.smoothingKernelSquare ./ max(obj.smoothingKernelSquare(:)); % Isabel wants this like the other

            % Take care of the possible infinite value for the speed
            obj.config.placemaps.criteria_speed_cm_per_second_maximum = eval(obj.config.placemaps.criteria_speed_cm_per_second_maximum);
            if obj.config.placemaps.criteria_speed_cm_per_second_maximum < 0
                error('The config value placemaps.criteria_speed_cm_per_second_maximum must be >= 0, but is %f.', obj.config.placemaps.criteria_speed_cm_per_second_maximum);
            end
            if obj.config.placemaps.criteria_speed_cm_per_second_maximum < obj.config.placemaps.criteria_speed_cm_per_second_minimum
                error('The config value placemaps.criteria_speed_cm_per_second_maximum (%f) must be greater than the minimum (%f).', ...
                    obj.config.placemaps.criteria_speed_cm_per_second_maximum, obj.config.placemaps.criteria_speed_cm_per_second_minimum);
            end
            
            % Read in the experiment file
            obj.experimentDescriptionFilename = fullfile(obj.recordingsParentFolder, 'experiment_description.json');
            if ~isfile( obj.experimentDescriptionFilename )
                error('Error! The file (%s) does not exist! How do you expect me to work?!', obj.experimentDescriptionFilename);
            end

            % Create the experiment structure
            obj.experiment = obj.mltp_create_session_folders( obj.recordingsParentFolder, obj.analysisParentFolder, obj.experimentDescriptionFilename );
            
            
            % These should go through a registration function to allow for
            % checking of duplicates
            %obj.availablePerTrialTasks('
            obj.availablePerSessionTasks('nvt_split_into_trial_nvt') = @obj.mltp_nvt_split_into_trial_nvt;
            obj.availablePerSessionTasks('trial_nvt_to_trial_fnvt') = @obj.mltp_trial_nvt_to_trial_fnvt;
            obj.availablePerSessionTasks('user_define_trial_arenaroi') = @obj.mltp_user_define_trial_arenaroi;
            obj.availablePerSessionTasks('make_trial_position_plots_raw') = @obj.mltp_make_trial_position_plots_raw;
            obj.availablePerSessionTasks('make_trial_position_plots_fixed') = @obj.mltp_make_trial_position_plots_fixed;
            obj.availablePerSessionTasks('make_session_orientation_plot_unaligned') = @obj.mltp_make_session_orientation_plot_unaligned;
            obj.availablePerSessionTasks('make_session_orientation_plot_aligned') = @obj.mltp_make_session_orientation_plot_aligned;
            obj.availablePerSessionTasks('trial_fnvt_to_trial_can_rect') = @obj.mltp_trial_fnvt_to_trial_can_rect;
            obj.availablePerSessionTasks('trial_fnvt_to_trial_can_square') = @obj.mltp_trial_fnvt_to_trial_can_square;   
            obj.availablePerSessionTasks('tfiles_to_singleunits_canon_rect') = @obj.mltp_tfiles_to_singleunits_canon_rect;
            obj.availablePerSessionTasks('compute_singleunit_placemap_data_rect') = @obj.mltp_compute_singleunit_placemap_data_rect;
            obj.availablePerSessionTasks('plot_singleunit_placemap_data_rect') = @obj.mltp_plot_singleunit_placemap_data_rect;
            obj.availablePerSessionTasks('tfiles_to_singleunits_canon_square') = @obj.mltp_tfiles_to_singleunits_canon_square;
            obj.availablePerSessionTasks('compute_singleunit_placemap_data_square') = @obj.mltp_compute_singleunit_placemap_data_square;
            obj.availablePerSessionTasks('plot_singleunit_placemap_data_square') = @obj.mltp_plot_singleunit_placemap_data_square;
            obj.availablePerSessionTasks('compute_best_fit_orientations_within_contexts') = @obj.mltp_compute_best_fit_orientations_within_contexts;
            obj.availablePerSessionTasks('compute_best_fit_orientations_all_contexts') = @obj.mltp_compute_best_fit_orientations_all_contexts;
            obj.availablePerSessionTasks('compute_best_fit_orientations_per_cell') = @obj.mltp_compute_best_fit_orientations_per_cell;
            obj.availablePerSessionTasks('compute_best_fit_orientations_0_180_per_cell') = @obj.mltp_compute_best_fit_orientations_0_180_per_cell;
            obj.availablePerSessionTasks('plot_across_within_0_180_similarity') = @obj.mltp_plot_across_within_0_180_similarity;
            obj.availablePerSessionTasks('plot_best_fit_orientations_per_cell') = @obj.mltp_plot_best_fit_orientations_per_cell;
            obj.availablePerSessionTasks('make_pfstats_excel') = @obj.mltp_make_pfstats_excel;
            
            obj.availablePerSessionTasks('plot_canon_rect_velspe') = @obj.mptp_plot_canon_rect_velspe;
            
            obj.availablePerSessionTasks('plot_nlx_mclust_plot_spikes_for_checking_bits') = @obj.mltp_nlx_mclust_plot_spikes_for_checking_bits;
            
            obj.availablePerExperimentTasks('plot_rate_difference_matrices') = @obj.mltp_plot_rate_difference_matrices;
            obj.availablePerExperimentTasks('plot_best_fit_orientations_within_contexts') = @obj.mltp_plot_best_fit_orientations_within_contexts;
            obj.availablePerExperimentTasks('plot_best_fit_orientations_all_contexts') = @obj.mltp_plot_best_fit_orientations_all_contexts;
            obj.availablePerExperimentTasks('plot_best_fit_orientations_averaged_across_sessions') = @obj.mltp_plot_best_fit_orientations_averaged_across_sessions;   
            
            
        end % function
        
        [experiment] = mltp_create_session_folders( obj, recordingsParentFolder, analysisParentFolder, experimentDescriptionFilename );
        
        mltp_nvt_split_into_trial_nvt(obj, session);
        mltp_trial_nvt_to_trial_fnvt(obj, session);
        mltp_trial_fnvt_to_trial_can_rect(obj, session);
        mltp_trial_fnvt_to_trial_can_square(obj, session);
        mltp_make_trial_position_plots_raw(obj, session);
        mltp_make_trial_position_plots_fixed(obj, session);
        mltp_user_define_trial_arenaroi(obj, session);
        mltp_tfiles_to_singleunits_canon_rect(obj, session);
        mltp_tfiles_to_singleunits_canon_square(obj, session);
        mltp_compute_singleunit_placemap_data_square(obj, session);
        mltp_compute_best_fit_orientations_all_contexts(obj, session);
        mltp_compute_best_fit_orientations_within_contexts(obj, session);
        mltp_compute_best_fit_orientations_per_cell(obj, session);
        mltp_compute_best_fit_orientations_0_180_per_cell(obj, session);
        mltp_compute_singleunit_placemap_data_rect(obj, session);
        mltp_plot_singleunit_placemap_data_rect(obj, session);
        mltp_plot_singleunit_placemap_data_square(obj, session);
        mltp_make_session_orientation_plot_unaligned(obj, session);
        mltp_make_session_orientation_plot_aligned(obj, session);
        mltp_plot_best_fit_orientations_within_contexts(obj);
        mltp_plot_best_fit_orientations_all_contexts(obj)
        mltp_plot_best_fit_orientations_averaged_across_sessions(obj);
        mltp_plot_best_fit_orientations_per_cell(obj, session);
        mltp_plot_best_fit_orientations_0_180_per_cell(obj, session);
        mltp_plot_across_within_0_180_similarity(obj, session);
        mltp_make_pfstats_excel(obj, session);
        mltp_plot_rate_difference_matrices(obj);
        mltp_nlx_mclust_plot_spikes_for_checking_bits(obj, session);
        mptp_plot_canon_rect_velspe(obj, session);
        
        function [contextTrialIds] = get_context_trial_ids(obj, session)
            % Get unique ids for the contexts. Dont assume that
            % they are just 1 or 1 and 2.
            uniqueContextIds = sort(unique(session.record.trial_info.contexts));
            numContexts = length(uniqueContextIds); % or use session.num_contexts;

            % Find the number of trials to use for each context
            % since they may not be identical (eg. 4 trials for
            % context 1, but 5 for context 2.
            contextTrialIds = cell(numContexts,1);
            numCols = 0;
            for iContext = 1:length(uniqueContextIds)
                contextId = uniqueContextIds(iContext);

                for iTrial = 1:session.num_trials_recorded
                    if session.record.trial_info.contexts(iTrial) == contextId && session.record.trial_info.use(iTrial) == 1
                        contextTrialIds{iContext} = [contextTrialIds{iContext} iTrial];
                    end
                end
                if length(contextTrialIds(iContext)) > numCols
                    numCols = length(contextTrialIds{iContext});
                end
            end
        end % function
        
        function [arena] = getArena(obj)
            arena = obj.experiment.info.arena;
        end % function
        
    end % methods
end % classdef
