close all
clear all
clc

pipeCfgFilename = fullfile(pwd, 'pipeline_config.json');

tstart = tic;

homework = [];

% Feature Rich
homework(1).subjectName = 'AK42_CA1';
homework(1).experiment = 'chengs_task_2c';
homework(1).feature = 'feature_rich';

homework(2).subjectName = 'AK74_CA1';
homework(2).experiment = 'chengs_task_2c';
homework(2).feature = 'feature_rich';

homework(3).subjectName = 'JJ9_CA1';
homework(3).experiment = 'chengs_task_2c';
homework(3).feature = 'feature_rich';

%experimentAnalysisParentFolder = '/work/muzziolab/marc/two_contexts_tetrode/analysis/feature_rich';

% Feature Poor
homework(4).subjectName = 'K1_CA1';
homework(4).experiment = 'chengs_task_2c';
homework(4).feature = 'feature_poor';

homework(5).subjectName = 'MG1_CA1';
homework(5).experiment = 'chengs_task_2c';
homework(5).feature = 'feature_poor';

homework(6).subjectName = 'HG1Y_CA1';
homework(6).experiment = 'chengs_task_2c';
homework(6).feature = 'feature_poor';

%experimentAnalysisParentFolder = '/work/muzziolab/marc/two_contexts_tetrode/analysis/feature_poor';

for iHomework = 1:length(homework)
    subjectName = homework(iHomework).subjectName;
    experiment = homework(iHomework).experiment;
    
    experimentAnalysisParentFolder = sprintf('/work/muzziolab/marc/two_contexts_tetrode/analysis/%s', homework(iHomework).feature);

    recordingsParentFolder = fullfile('/work/muzziolab/DATA/tinimice', subjectName, 'recordings', experiment);
    analysisParentFolder = fullfile(experimentAnalysisParentFolder, subjectName);

    pipe = MLTetrodePipeline( pipeCfgFilename, recordingsParentFolder, analysisParentFolder);

    fprintf('%10.10s: ', subjectName);
    for iSession = 1:pipe.experiment.numSessions
        session = pipe.experiment.session{iSession};
       fprintf('%10.0d\t', session.num_tfiles);
    end
    fprintf('\n');
    
%     pipe.executePerSessionTask('nvt_split_into_trial_nvt');
% %     pipe.executePerSessionTask('user_define_trial_arenaroi');
%     pipe.executePerSessionTask('trial_nvt_to_trial_fnvt');
%     pipe.executePerSessionTask('trial_fnvt_to_trial_can_rect');
%     pipe.executePerSessionTask('trial_fnvt_to_trial_can_square');
%     pipe.executePerSessionTask('tfiles_to_singleunits_canon_rect');
%     pipe.executePerSessionTask('tfiles_to_singleunits_canon_square');
% 
%     pipe.executePerSessionTask('compute_singleunit_placemap_data_rect');
%     pipe.executePerSessionTask('compute_singleunit_placemap_data_square');
%     pipe.executePerSessionTask('make_pfstats_excel')
% 
%     pipe.executePerSessionTask('compute_best_fit_orientations_within_contexts');
%     pipe.executePerSessionTask('compute_best_fit_orientations_all_contexts');
%     pipe.executePerSessionTask('compute_best_fit_orientations_per_cell');
%     pipe.executePerSessionTask('compute_best_fit_orientations_0_180_per_cell');
%     
% 
%     pipe.executePerSessionTask('make_trial_position_plots_raw');
%     pipe.executePerSessionTask('make_trial_position_plots_fixed');
%     pipe.executePerSessionTask('make_session_orientation_plot_unaligned');
%     pipe.executePerSessionTask('make_session_orientation_plot_aligned');
% 
%     pipe.executePerSessionTask('plot_canon_rect_velspe');
%     pipe.executePerSessionTask('plot_singleunit_placemap_data_rect');
%     pipe.executePerSessionTask('plot_singleunit_placemap_data_square');
%     pipe.executePerSessionTask('plot_best_fit_orientations_0_180_per_cell');
%     pipe.executePerSessionTask('plot_across_within_0_180_similarity');
%     pipe.executePerSessionTask('plot_nlx_mclust_plot_spikes_for_checking_bits');
% 
%     pipe.executeExperimentTask('plot_best_fit_orientations_all_contexts');
%     pipe.executeExperimentTask('plot_best_fit_orientations_within_contexts');
    
    %Only works if more than one session
%     pipe.executeExperimentTask('plot_best_fit_orientations_averaged_across_sessions');
%     
%     pipe.executeExperimentTask('plot_rate_difference_matrices');
%     
%     copyfile(pipeCfgFilename, analysisParentFolder);
%     
end % for subject
telapsed = toc(tstart);
%disp(telapsed/60.0)
fprintf('Analysis completed.\n');
