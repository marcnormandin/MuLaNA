close all
clear all
clc

tstart = tic;


% Don't change these
projectCfgFilename = fullfile(pwd, 'project_config.json');
pipeCfgFilename = fullfile(pwd, 'pipeline_config_square.json');
errorFilename = fullfile(pwd, 'error.txt');

% Read in the project configuration file
if ~isfile( projectCfgFilename )
    error('The project configuration file (%s) does not exist.', projectCfgFilename);
end
try 
    projectConfig = jsondecode( fileread(projectCfgFilename) );
catch ME
    error('Error encountered while reading project configuration from (%s): %s', projectCfgFilename, ME.identifier)
end
     
DATA_FOLDER = projectConfig.dataFolder;
ANALYSIS_FOLDER = projectConfig.analysisFolder;

data = [];
folders = dir(DATA_FOLDER);
for iFolder = 1:length(folders)
    folder = folders(iFolder).name;
    if strcmp(folder, '.') || strcmp(folder, '..')
        continue;
    end
    if isfolder(fullfile(DATA_FOLDER, folder))
        k = length(data) + 1;
        data(k).subjectName = folder;
        data(k).experiment = 'object_task_consecutive_trials';
    end
end

homeworkIds = [];

if isempty(data)
    fprintf('There are no datasets to process! Done!\n');
else
    while true
        if ~isempty(homeworkIds)
            fprintf('We will process:\n');
            for i = 1:length(homeworkIds)
                did = homeworkIds(i);
                fprintf('\t%s\n', data(did).subjectName);
                %homework(i).experiment = 'object_task_consecutive_trials';
            end % i
        end
        
        fprintf('The following datasets are available:\n');
        fprintf('%0.2d:\t Add all (Get a coffee!!)\n', 0);
        for iData = 1:length(data)
            if ismember(iData, homeworkIds)
                continue;
            else
                fprintf('%0.2d:\t Add %s\n', iData, data(iData).subjectName);
            end
        end
        fprintf('%0.2d:\t (stop adding)\n', length(data)+1);
        
        choice = input('? ');
        if choice == 0
            homeworkIds = 1:length(data);
            break;
        elseif choice == length(data)+1
            break;
        else
            homeworkIds(end+1) = choice;
            homeworkIds = unique(homeworkIds);
        end
    end
end

for i = 1:length(homeworkIds)
    did = homeworkIds(i);
    homework(i).subjectName = data(did).subjectName;
    homework(i).experiment = 'object_task_consecutive_trials';
end % i

%%
% remove any previous error file
if isfile(errorFilename)
    delete(errorFilename)
end

% Let's be good and do our homework
for iHomework = 1:length(homework)
    subjectName = homework(iHomework).subjectName;
    experiment = homework(iHomework).experiment;
    
    fprintf('Processing %d of %d: %s\n', iHomework, length(homework), subjectName);
    
    recordingsParentFolder = fullfile(DATA_FOLDER, subjectName, 'recordings', experiment);
    analysisParentFolder = fullfile(ANALYSIS_FOLDER, subjectName);

try
    pipe = MLTetrodePipeline( pipeCfgFilename, recordingsParentFolder, analysisParentFolder);

    pipe.executePerSessionTask('nvt_split_into_trial_nvt');
    
    % Ask the user to create the ROIs only when needed (ideally only once)
    for iSession = 1:pipe.experiment.numSessions
        session = pipe.experiment.session{iSession};
        numTrials = session.num_trials_recorded;
        roiFiles = dir(fullfile(session.rawFolder, 'trial_*_arenaroi.mat'));
        numRois = length(roiFiles);
        
        if numRois ~= numTrials
            pipe.executePerSessionTaskByIndex('user_define_trial_arenaroi', iSession);
        end
    end
    %pipe.executePerSessionTask('user_define_trial_arenaroi');

    pipe.executePerSessionTask('trial_nvt_to_trial_fnvt');
    pipe.executePerSessionTask('trial_fnvt_to_trial_can_rect');
    pipe.executePerSessionTask('trial_fnvt_to_trial_can_square');
    pipe.executePerSessionTask('tfiles_to_singleunits_canon_rect');
    pipe.executePerSessionTask('tfiles_to_singleunits_canon_square');

    pipe.executePerSessionTask('compute_singleunit_placemap_data_rect');
    pipe.executePerSessionTask('compute_singleunit_placemap_data_square');
    %pipe.executePerSessionTask('make_pfstats_excel')

    pipe.executePerSessionTask('compute_best_fit_orientations_within_contexts');
    pipe.executePerSessionTask('compute_best_fit_orientations_all_contexts');
    pipe.executePerSessionTask('compute_best_fit_orientations_per_cell');
    pipe.executePerSessionTask('compute_best_fit_orientations_0_180_per_cell');
    
    pipe.executePerSessionTask('make_trial_position_plots_raw');
    pipe.executePerSessionTask('make_trial_position_plots_fixed');
    pipe.executePerSessionTask('make_session_orientation_plot_unaligned');
    pipe.executePerSessionTask('make_session_orientation_plot_aligned');

    pipe.executePerSessionTask('plot_canon_rect_velspe');
    pipe.executePerSessionTask('plot_singleunit_placemap_data_rect');
    pipe.executePerSessionTask('plot_singleunit_placemap_data_square');
    pipe.executePerSessionTask('plot_best_fit_orientations_0_180_per_cell');
    pipe.executePerSessionTask('plot_across_within_0_180_similarity');
    pipe.executePerSessionTask('plot_nlx_mclust_plot_spikes_for_checking_bits');

    pipe.executeExperimentTask('plot_best_fit_orientations_all_contexts');
    pipe.executeExperimentTask('plot_best_fit_orientations_within_contexts');
    
    pipe.executeExperimentTask('plot_best_fit_orientations_averaged_across_sessions');
    
    pipe.executeExperimentTask('plot_rate_difference_matrices');

    object_task_correlations(pipe);
catch ME
    fid = fopen(errorFilename, 'w+');
    if fid == -1
        error('Unable to create the error file! Doubly-bad!!\n');
    end
    
    fprintf(fid, 'Error running %s: %s\n', subjectName, getReport(ME));
    fclose(fid);
end
    copyfile(pipeCfgFilename, analysisParentFolder);
    
end % for subject
telapsed = toc(tstart);
disp(telapsed/60.0)
