%2022-01-04. This function is called after the DLC python scripts have
%already made the behavCam#DLC_resetnet50_*.h5 files in the recordings_sep
%folders.
% Written for CMG129_CA1 session 4 because I couldn't find the other
% script!!! 

close all
clear all
clc

config = mulana_json_read(fullfile('R:\chengs_task_2c\code\ucla_miniscope\NotUSed', 'pipeline_config.json'));
experimentDescriptionSepFilename = 'T:\Minimice\feature_rich\CMG129_CA1\recordings_sep\experiment_description.json';

settings = ml_miniscope_pipeline_concatenated_load(experimentDescriptionSepFilename);
%pipeSep = MLMiniscopePipeline(config, settings.recordingsParentFolderSep,  settings.analysisParentFolderSep);
pipeSat = MLMiniscopePipeline(config, settings.recordingsParentFolderSat,  settings.analysisParentFolderSat);


%% We need to create the dlc_tracks_sep folder if it doesn't already exist.

tmp = split(pipeSat.AnalysisParentFolder, filesep);
tmp2 = fullfile(join(tmp(1:end-1), filesep), 'dlc_tracks_sep');
dlc_tracks_sep_parent_folder = tmp2{1}

if ~exist(dlc_tracks_sep_parent_folder, 'dir')
    mkdir(dlc_tracks_sep_parent_folder);
    
end

numSessions = pipeSat.Experiment.getNumSessions();
for iSession = 1:numSessions
    session = pipeSat.Experiment.getSession(iSession);
    sessionName = session.getName();
    
    numTrials = session.getNumTrials();
    for iTrial = 1:numTrials
       trial = session.getTrialByOrder(iTrial);
       recTrialFolder = trial.getTrialDirectory();
       fprintf('Processing: %d of %d: %s\n', iTrial, numTrials, recTrialFolder);
       
       % Get a list of the behav files
       fileList = dir(fullfile(recTrialFolder, 'behavCam*DLC_*.h5'));
       fprintf('Found %d files to copy and rename.\n', length(fileList));
       for iFile = 1:length(fileList)
          ff = fileList(iFile).folder;
          fn = fileList(iFile).name;
          
          tmp = split(ff, filesep);
          off = fullfile(dlc_tracks_sep_parent_folder, sessionName, tmp{end});
          
          indD = strfind(fn, 'DLC_resnet50');
          ofn = [fn(1:(indD-1)) '_DLC.h5'];
          
          
          
          originalFilename = fullfile(ff, fn);
          outputFilename = fullfile(off, ofn);
          % We need to remove the specific model used from the filename
          
          fprintf('\tcopying %s to %s\n', originalFilename, outputFilename);
          
          if ~exist(off, 'dir')
              mkdir(off);
          end
          
          copyfile(originalFilename, outputFilename);
       end
    end
end
