% May 5, 2020
% Isabel gave me a dataset with 23 experiments with 5 sessions each. Some
% of the sessions had a second trial that was junk (only a few points) so
% the following code fixes these records, and it also forces the bits to be
% 32.

close all
clear all
clc

tstart = tic;

% Don't change these
projectCfgFilename = fullfile(pwd, 'project_config.json');
pipeCfgFilename = fullfile(pwd, 'pipeline_config.json');

% Report what is being used to the user so that they are aware.
fprintf('Using the following configuration files:\n');
fprintf('\t Project configuration: %s\n', projectCfgFilename);
fprintf('\t Pipeline configuration: %s\n', pipeCfgFilename);
fprintf('\n');

% Read in the project configuration file
if ~isfile( projectCfgFilename )
    error('The project configuration file (%s) does not exist.', projectCfgFilename);
end
try 
    fprintf('Loading the project configuration from: %s\n', projectCfgFilename);
    projectConfig = jsondecode( fileread(projectCfgFilename) );
    fprintf('\tcompleted loading.\n');
catch ME
    error('Error encountered while reading project configuration from (%s): %s', projectCfgFilename, ME.identifier)
end
     
DATA_FOLDER = projectConfig.dataFolder;
ANALYSIS_FOLDER = projectConfig.analysisFolder;

% Search all subdirectories of DATA_FOLDER for files named
% 'experiment_description.json' and store their data in an array.
experimentDescriptions = dir(fullfile(DATA_FOLDER, '**', 'experiment_description.json')); 
data = [];
for iExp = 1:length(experimentDescriptions)
    edFilename = fullfile(experimentDescriptions(iExp).folder, experimentDescriptions(iExp).name);
    
    % Try to read the file to get its information
    if ~isfile( edFilename )
        error('The session record (%s) does not exist.', edFilename);
    end
    edjson = [];
    try 
        edjson = jsondecode( fileread(edFilename) );
    catch ME
        fprintf('Error encountered while reading from (%s): %s', edFilename, ME.identifier)
        continue; % skip this file
    end
    k = length(data)+1;
    data(k).edFolder = experimentDescriptions(iExp).folder;
    data(k).edFilename = edFilename;
    data(k).subjectName = edjson.animal;
    data(k).experiment = edjson.experiment;
    data(k).region = edjson.imaging_region;
    data(k).arena = edjson.arena;
end % iExp


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
                fprintf('%0.2d:\t Add %s %s (%s)\n', iData, data(iData).subjectName, data(iData).experiment, data(iData).edFolder(length(DATA_FOLDER)+1:end));
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
end % i


% Let's be good and do our homework
for iHomework = 1:length(homework)
    subjectName = homework(iHomework).subjectName;
    experiment = homework(iHomework).experiment;
    edFilename = homework(iHomework).edFilename;
    edFolder = homework(iHomework).edFolder;
    
    fprintf('Processing %d of %d: %s\n', iHomework, length(homework), subjectName);
    
    recordingsParentFolder = edFolder;
    %analysisParentFolder = fullfile(ANALYSIS_FOLDER, subjectName); % dont use experiment since it should be object task
    
    % replicate same structure as that of the recordings
    analysisParentFolder = replace(recordingsParentFolder, DATA_FOLDER, ANALYSIS_FOLDER);
    
    % If the pipeline has an error running a dataset, then save the error
    % to this file so the user can find out what went wrong.
    errorFilename = fullfile(pwd, sprintf('%s_error.txt', subjectName));
    
    % Remove any previous error file since we are starting anew
    if isfile(errorFilename)
        delete(errorFilename)
    end
    
    try
        pipe = MLTetrodePipeline( pipeCfgFilename, recordingsParentFolder, analysisParentFolder);

        % Load the experiment description
        exp = ml_util_json_read( edFilename );
        
        % Force bits to be 32
        exp.mclust_tfile_bits = 32;
        
        ml_util_json_save( exp, edFilename );
        
        % The session records are already loaded, so drop them in memory
        numSessions = pipe.experiment.numSessions;
        for iSession = 1:numSessions
            session = pipe.experiment.session{iSession};
            sr = session.sessionRecord;
            n = sr.getNumTrialsToProcess();
            ti = sr.getTrialsToProcess();
            if n > 1
                fprintf('%s : %s has %d trials\n', pipe.experiment.subjectName, session.name, sr.getNumTrialsToProcess());
                for iTrial = 2:n
                    tid = ti(iTrial).id;
                    sr.dropTrialId(tid);
                end 
            end
            sr.saveFile()
        end % iSession
        
        numSessions = pipe.experiment.numSessions;
        for iSession = 1:numSessions
            session = pipe.experiment.session{iSession};
            sr = session.sessionRecord;
            n = sr.getNumTrialsToProcess();
            ti = sr.getTrialsToProcess();
            if n > 1
                fprintf('%s : %s has %d trials\n', pipe.experiment.subjectName, session.name, sr.getNumTrialsToProcess());
                error('');
            end
        end % iSession
    
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

end % for subject

% Report the computation time
telapsed_mins = toc(tstart)/60;
fprintf('Computation time was %0.3f minutes.\n', telapsed_mins);

