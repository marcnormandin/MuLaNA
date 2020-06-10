close all
clear all
clc

tstart = tic;


% Don't change these
projectCfgFilename = fullfile(pwd, 'project_config.json');
pipeCfgFilename = fullfile(pwd, 'pipeline_config.json');

% Load the project configuration
projectConfig = mulana_json_read( projectCfgFilename );
disp(projectConfig)

% Search for mice
[featurePoor, descFP_bad] = mulana_experiment_descriptions_search( projectConfig.dataFeaturePoorFolder );
[featureRich, descFR_bad] = mulana_experiment_descriptions_search( projectConfig.dataFeatureRichFolder );

% Report any problems
for i = 1:length(descFP_bad)
    fprintf('Problems encountered reading feature poor: %s\n', descFP_bad.folder);
end
for i = 1:length(descFR_bad)
    fprintf('Problems encountered reading feature rich: %s\n', descFR_bad.folder);
end

% Add the mice data so user can be selective
data = [];
for iExp = 1:length(featurePoor)
    k = length(data)+1;
    edjson = featurePoor(iExp).json;
    data(k).edFolder = featurePoor(iExp).folder;
    data(k).edFilename = featurePoor(iExp).fullFilename;
    data(k).subjectName = edjson.animal;
    data(k).experiment = edjson.experiment;
    data(k).region = edjson.imaging_region;
    data(k).arena = edjson.arena;
    data(k).recordingsParentFolder = featurePoor(iExp).folder;
    data(k).analysisParentFolder = fullfile(projectConfig.analysisFeaturePoorFolder, data(k).subjectName);
    data(k).featureType = 'poor';
end % iExp
for iExp = 1:length(featureRich)
    k = length(data)+1;
    edjson = featureRich(iExp).json;
    data(k).edFolder = featureRich(iExp).folder;
    data(k).edFilename = featureRich(iExp).fullFilename;
    data(k).subjectName = edjson.animal;
    data(k).experiment = edjson.experiment;
    data(k).region = edjson.imaging_region;
    data(k).arena = edjson.arena;
    data(k).recordingsParentFolder = featureRich(iExp).folder;
    data(k).analysisParentFolder = fullfile(projectConfig.analysisFeatureRichFolder, data(k).subjectName);
    data(k).featureType = 'rich';
end % iExp

homeworkIds = [];

% Present user with a menu of options
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
                fprintf('%0.2d:\t Add %s (feature %s) [%s]\n', iData, data(iData).subjectName, data(iData).featureType, data(iData).recordingsParentFolder);
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

homework = [];
% Collect the homework to do based on what the user selected
for i = 1:length(homeworkIds)
    did = homeworkIds(i);
    homework(i).subjectName = data(did).subjectName;
    homework(i).experiment = data(did).experiment;
    homework(i).edFolder = data(did).edFolder;
    homework(i).edFilename = data(did).edFilename;
    homework(i).analysisParentFolder = data(did).analysisParentFolder;
    homework(i).recordingsParentFolder = data(did).recordingsParentFolder;
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

makeMiceAveragedPlots = true;
while true
    fprintf('It is better to say yes\n');
    makeMiceAveragedPlots = input('Do you want to make mice averaged plots [y/n]? ', 's');
    if strcmpi(makeMiceAveragedPlots, 'y')
        makeMiceAveragedPlots = true;
        break;
    elseif strcmpi(makeMiceAveragedPlots, 'n')
        makeMiceAveragedPlots = false;
        break;
    else
        fprintf('(y)es or (n)o only.\n');
    end
end % while


%
% Let's be good and do our homework
for iHomework = 1:length(homework)
    subjectName = homework(iHomework).subjectName;
    experiment = homework(iHomework).experiment;
    edFilename = homework(iHomework).edFilename;
    edFolder = homework(iHomework).edFolder;
    
    fprintf('Processing %d of %d: %s\n', iHomework, length(homework), subjectName);
    
    recordingsParentFolder = homework(iHomework).edFolder;
    analysisParentFolder = homework(iHomework).analysisParentFolder;
    
    
    % If the pipeline has an error running a dataset, then save the error
    % to this file so the user can find out what went wrong.
    errorFilename = fullfile(pwd, sprintf('%s_error.txt', subjectName));
    
    % Remove any previous error file since we are starting anew
    if isfile(errorFilename)
        delete(errorFilename)
    end

    if cleanAnalysisFolder 
        if exist(analysisParentFolder, 'dir')
            rmdir(analysisParentFolder, 's');
            fprintf('Deleted previous analysis results for %s\n', subjectName);
        end
    end
    
    try
        pipeCfg = ml_util_json_read( pipeCfgFilename );
        pipe = MLTetrodePipeline( pipeCfg, recordingsParentFolder, analysisParentFolder);

        pipe.executePerSessionTask('nvt_split_into_trial_nvt');

        % Ask the user to create the ROIs only when needed (ideally only once)
        % We to have the ROI before the other parts of the pipeline can run.
        for iSession = 1:pipe.Experiment.getNumSessions()
            session = pipe.Experiment.getSession(iSession);

            % Check if we have all of the ROI needs for the analysis
            missingRoi = false;
            for iTrial = 1:session.getNumTrials()
                trial = session.getTrial(iTrial);
                % Check if we are missing the required ROI
                if ~isfile(fullfile(session.getSessionDirectory(), sprintf('trial_%d_arenaroi.mat', trial.getTrialId())))
                    missingRoi = true;
                    break;
                end
            end

            if missingRoi
                pipe.executeSessionTask('user_define_trial_arenaroi', session);
            end
        end

        pipe.executePerSessionTask('trial_nvt_to_trial_fnvt');
        pipe.executePerSessionTask('trial_fnvt_to_trial_can_movement');
        pipe.executePerSessionTask('tfiles_to_singleunits');
        pipe.executePerSessionTask('compute_singleunit_placemap_data');
        pipe.executePerSessionTask('compute_singleunit_placemap_data_shrunk');

        % ANALYSIS COMPUTATIONS
        pipe.executePerSessionTask('make_pfstats_excel')
        
        pipe.executePerSessionTask('compute_bfo_90_ac');
        pipe.executePerSessionTask('compute_bfo_90_wc');
        pipe.executePerSessionTask('compute_bfo_90_ac_per_cell');
    %     pipe.executePerSessionTask('compute_best_fit_orientations_0_180_per_cell');

        pipe.executePerSessionTask('make_trial_position_plots_raw');
        pipe.executePerSessionTask('make_trial_position_plots_fixed');
        pipe.executePerSessionTask('make_session_orientation_plot_unaligned');
        pipe.executePerSessionTask('make_session_orientation_plot_aligned');

        pipe.executePerSessionTask('plot_movement');
        pipe.executePerSessionTask('plot_nlx_mclust_plot_spikes_for_checking_bits');
        
        pipe.executePerSessionTask('plot_placemaps');

        % ANALYSIS PLOTS
        pipe.executeExperimentTask('plot_bfo_90_ac');
        pipe.executeExperimentTask('plot_bfo_90_wc');
        pipe.executePerSessionTask('plot_bfo_90_ac_per_cell');

        %pipe.executePerSessionTask('plot_best_fit_orientations_0_180_per_cell');
    
    
%         pipe.executePerSessionTask('plot_across_within_0_180_similarity');
  
        pipe.executeExperimentTask('plot_bfo_90_averaged_across_sessions');

        pipe.executePerSessionTask('plot_rate_difference_matrices');
        pipe.executeExperimentTask('plot_rate_difference_matrix_average_days');
        pipe.executePerSessionTask('plot_behaviour_averaged_placemaps');
        pipe.executePerSessionTask('plot_behaviour_averaged_placemaps_contexts');

    catch ME
        % record the error
        fid = fopen(errorFilename, 'w+');
        if fid == -1
            error('Unable to create the error file! Doubly-bad!!\n');
        end

        fprintf(fid, 'Error running %s: %s\n', subjectName, getReport(ME));
        fclose(fid);
    end
    
    if isfile(errorFilename)
        fprintf('An error occurred in the course of this program running.\n');
        fprintf('View the error file (%s) for clues as to what errors occurred.\n', errorFilename);
        
        % Get the user's attention
        f = msgbox(sprintf('An error occurred. See the file %s for clues as to why.', errorFilename), 'Error','error');
    end

    % Put a copy of the settings that we used in the analysis folder
    % so that we will always know what was used.
    copyfile(pipeCfgFilename, analysisParentFolder);
end % for subject



if makeMiceAveragedPlots
    % Now run the code that requires the previous analyses to exist
    ml_two_contexts_plot_best_fit_alignment(projectConfig);
    ml_two_contexts_plot_averaged_combined_orientation(projectConfig, 'all');
    ml_two_contexts_plot_averaged_combined_orientation(projectConfig, 'within');
end

% Report the computation time
telapsed_mins = toc(tstart)/60;
fprintf('Computation time was %0.3f minutes.\n', telapsed_mins);
