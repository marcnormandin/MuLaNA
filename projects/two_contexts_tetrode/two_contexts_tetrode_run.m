close all
clear all
clc

tstart = tic;


% Don't change these
projectCfgFilename = fullfile(pwd, 'project_config.json');
pipeCfgFilename = fullfile(pwd, 'pipeline_config.json');
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


% Feature Poor
homework(4).subjectName = 'K1_CA1';
homework(4).experiment = 'chengs_task_2c';
homework(4).feature = 'feature_poor';

homework(5).subjectName = 'MG1_CA1';
homework(5).experiment = 'chengs_task_2c';
homework(5).feature = 'feature_poor';

% HG1Y_CA1 is not yet usable because we only have day 4 (currently).
% 2020-04-15
% homework(6).subjectName = 'HG1Y_CA1';
% homework(6).experiment = 'chengs_task_2c';
% homework(6).feature = 'feature_poor';


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


for iHomework = 1:length(homework)
    subjectName = homework(iHomework).subjectName;
    experiment = homework(iHomework).experiment;
    
    experimentAnalysisParentFolder = sprintf('%s/%s', projectConfig.analysisFolder, homework(iHomework).feature);

    recordingsParentFolder = fullfile(projectConfig.dataFolder, subjectName, 'recordings', experiment);
    analysisParentFolder = fullfile(experimentAnalysisParentFolder, subjectName);

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
        numTrials = session.num_trials_recorded;
        roiFiles = dir(fullfile(session.rawFolder, 'trial_*_arenaroi.mat'));
        numRois = length(roiFiles);
        
        if numRois ~= numTrials
            pipe.executePerSessionTaskByIndex('user_define_trial_arenaroi', iSession);
        end
    end

    % Remove outliers and smooth the points. Requires the ROI.
    pipe.executePerSessionTask('trial_nvt_to_trial_fnvt');
    
    % Transform coordinates to standard orientation for a rectangle
    pipe.executePerSessionTask('trial_fnvt_to_trial_can_rect');
    
    % Same for square
    pipe.executePerSessionTask('trial_fnvt_to_trial_can_square');
    
    % Transform the t-files and separate into trials
    pipe.executePerSessionTask('tfiles_to_singleunits_canon_rect');
    pipe.executePerSessionTask('tfiles_to_singleunits_canon_square');

    % Compute the placemaps, but don't plot them yet.
    pipe.executePerSessionTask('compute_singleunit_placemap_data_rect');
    pipe.executePerSessionTask('compute_singleunit_placemap_data_square');
    
    % Compute placefield statistics
    pipe.executePerSessionTask('make_pfstats_excel')

    % Compute the pixel-pixel cross-correlations
    % These require square canonical shape
    pipe.executePerSessionTask('compute_best_fit_orientations_within_contexts');
    pipe.executePerSessionTask('compute_best_fit_orientations_all_contexts');
    pipe.executePerSessionTask('compute_best_fit_orientations_per_cell');
    
    % These require being a rectangle
    pipe.executePerSessionTask('compute_best_fit_orientations_0_180_per_cell');
    
    % Plot the raw position data
    pipe.executePerSessionTask('make_trial_position_plots_raw');
    
    % Plot the fixed/smoothed position data
    pipe.executePerSessionTask('make_trial_position_plots_fixed');
    
    % Plot a single figure showing the fixed position in video frame
    % coordinates.
    pipe.executePerSessionTask('make_session_orientation_plot_unaligned');
    
    % Plot a single figure show the fixed positions in canonical
    % coordiantes
    pipe.executePerSessionTask('make_session_orientation_plot_aligned');

    % Make the plot of the speed for each trial.
    pipe.executePerSessionTask('plot_canon_rect_velspe');
    
    % Plot the placemaps for the rectangle 
    pipe.executePerSessionTask('plot_singleunit_placemap_data_rect');
    
    % Plot the placemaps for the square
    pipe.executePerSessionTask('plot_singleunit_placemap_data_square');
    
    % Plot the 0/180 best fit plots per cell/single unit
    pipe.executePerSessionTask('plot_best_fit_orientations_0_180_per_cell');
    
    % Plot the 0,90,180,270 best fit orienations per cell/single unit
    % Requires square canaonical shape
    pipe.executePerSessionTask('plot_best_fit_orientations_per_cell');
    
    % Plot the 0 vs 180 best aligned similarity plots (cumulative)
    pipe.executePerSessionTask('plot_across_within_0_180_similarity');
    
    % Plot the spike times for each tfile as 32bit and 64bit, to show
    % which is correct. Correct is when all the spikes are contained
    % in the green rectangle.
    pipe.executePerSessionTask('plot_nlx_mclust_plot_spikes_for_checking_bits');

    % Plot the 0,90,180,270 for all contexts
    pipe.executeExperimentTask('plot_best_fit_orientations_all_contexts');
    
    % Plot the 0,90,180,270 results only comparing trials from the same
    % context.
    pipe.executeExperimentTask('plot_best_fit_orientations_within_contexts');
    
    % Plot the averaged results across sessions (for one animal).
    pipe.executeExperimentTask('plot_best_fit_orientations_averaged_across_sessions');
    
    % Plot the rate difference matrices for each single unit
    % and the average over all single units.
    pipe.executeExperimentTask('plot_rate_difference_matrices');

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

% Now run the code that requires the previous analysis to exist
% These are specific to the Muzzio Lab project.
ml_two_contexts_plot_best_fit_alignment(projectConfig);
ml_two_contexts_plot_rates_across_and_within(projectConfig);
ml_two_contexts_plot_averaged_combined_orientation(projectConfig, 'all');
ml_two_contexts_plot_averaged_combined_orientation(projectConfig, 'within');


% Report the computation time
telapsed_mins = toc(tstart)/60;
fprintf('Compute time was %0.3f minutes.\n', telapsed_mins);

if ~isfile(errorFilename)
    fprintf('Program ended normally! Have a great day!\n');
else
    fprintf('An error occurred in the course of this program running.\n');
    fprintf('View the error file (%s) for clues as to what errors occurred.\n', errorFilename);
end

