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

% Ask the user if they want to clean the analysis folder for the subjects
% that will be analyzed. It is better to do this if t-files change.
cleanAnalysisFolder = true;
while true
    fprintf('It is better to say yes\n');
    cleanAnalysisFolder = input('Do you want to delete each subjects previous analysis folder [y/n]? ', 's');
    if strcmpi(cleanAnalysisFolder, 'y')
        cleanAnalysisFolder = true;
        break;
    elseif strcmpi(cleanAnalysisFolder, 'n')
        cleanAnalysisFolder = false;
        break;
    else
        fprintf('(y)es or (n)o only.\n');
    end
end % while

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

    if cleanAnalysisFolder 
        if exist(analysisParentFolder, 'dir')
            rmdir(analysisParentFolder, 's');
            fprintf('Deleted previous analysis results for %s\n', subjectName);
        end
    end
    
try
    pipe = MLTetrodePipeline( pipeCfgFilename, recordingsParentFolder, analysisParentFolder);

    pipe.executePerSessionTask('nvt_split_into_trial_nvt');
    
    % Ask the user to create the ROIs only when needed (ideally only once)
    for iSession = 1:pipe.experiment.numSessions
        session = pipe.experiment.session{iSession};
        
        sr = session.sessionRecord;
        ti = sr.getTrialsToProcess();
        trialIds = [ti.id];
        
        % Check if we have all of the ROI needs for the analysis
        missingRoi = false;
        for iTrial = 1:sr.getNumTrialsToProcess()
            % Check if we are missing the required ROI
            if ~isfile(fullfile(session.rawFolder, sprintf('trial_%d_arenaroi.mat', trialIds(iTrial))))
                missingRoi = true;
                break;
            end
        end
        
        if missingRoi
            pipe.executePerSessionTaskByIndex('user_define_trial_arenaroi', iSession);
        end
    end

    pipe.executePerSessionTask('trial_nvt_to_trial_fnvt');
    pipe.executePerSessionTask('trial_fnvt_to_trial_can_rect');
    pipe.executePerSessionTask('trial_fnvt_to_trial_can_square');
    pipe.executePerSessionTask('tfiles_to_singleunits_canon_rect');
    pipe.executePerSessionTask('tfiles_to_singleunits_canon_square');

    pipe.executePerSessionTask('compute_singleunit_placemap_data_rect');
    pipe.executePerSessionTask('compute_singleunit_placemap_data_square');
    pipe.executePerSessionTask('make_pfstats_excel')

    pipe.executePerSessionTask('compute_best_fit_orientations_within_contexts');
    pipe.executePerSessionTask('compute_best_fit_orientations_all_contexts');
    pipe.executePerSessionTask('compute_best_fit_orientations_per_cell');
    pipe.executePerSessionTask('compute_best_fit_orientations_0_180_per_cell');
    
    pipe.executePerSessionTask('make_trial_position_plots_raw');
    pipe.executePerSessionTask('make_trial_position_plots_fixed');
    pipe.executePerSessionTask('make_session_orientation_plot_unaligned');
    pipe.executePerSessionTask('make_session_orientation_plot_aligned');

    pipe.executePerSessionTask('plot_canon_rect_velspe');
    
    if strcmpi(pipe.getArena().shape, 'rectangle')
        pipe.executePerSessionTask('plot_singleunit_placemap_data_rect');
    elseif strcmpi(pipe.getArena().shape, 'square')
        pipe.executePerSessionTask('plot_singleunit_placemap_data_square');
    end
    
    pipe.executePerSessionTask('plot_best_fit_orientations_0_180_per_cell');
    pipe.executePerSessionTask('plot_best_fit_orientations_per_cell');

    pipe.executePerSessionTask('plot_across_within_0_180_similarity');
    pipe.executePerSessionTask('plot_nlx_mclust_plot_spikes_for_checking_bits');

    pipe.executeExperimentTask('plot_best_fit_orientations_all_contexts');
    pipe.executeExperimentTask('plot_best_fit_orientations_within_contexts');
    
    pipe.executeExperimentTask('plot_best_fit_orientations_averaged_across_sessions');
    
    pipe.executeExperimentTask('plot_rate_difference_matrices');

    % custom to this analysis
    object_task_correlations(pipe);
catch ME
    % record the error
    fid = fopen(errorFilename, 'w+');
    if fid == -1
        error('Unable to create the error file! Doubly-bad!!\n');
    end
    
    fprintf(fid, 'Error running %s: %s\n', subjectName, getReport(ME));
    fclose(fid);
end
    % Put a copy of the settings that we used in the analysis folder
    % so that we will always know what was used.
    copyfile(pipeCfgFilename, analysisParentFolder);
end % for subject

% Report the computation time
telapsed_mins = toc(tstart)/60;
fprintf('Compute time was %0.3f minutes.\n', telapsed_mins);

if ~isfile(errorFilename)
    fprintf('Program ended normally! Have a great day!\n');
else
    fprintf('An error occurred in the course of this program running.\n');
    fprintf('View the error file (%s) for clues as to what errors occurred.\n', errorFilename);
end
