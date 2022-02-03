% This is a one-off script. It was written to process the concatenated
% CNFMe into the separate trial results

close all
clear all
clc
fclose('all');

%%
config = mulana_json_read(fullfile('R:\chengs_task_2c\code\ucla_miniscope\NotUSed', 'pipeline_config.json'));
experimentDescriptionSepFilename = 'T:\Minimice\feature_rich\CMG129_CA1\recordings_sep\experiment_description.json';

settings = ml_miniscope_pipeline_concatenated_load(experimentDescriptionSepFilename);
%pipeSep = MLMiniscopePipeline(config, settings.recordingsParentFolderSep,  settings.analysisParentFolderSep);
pipeSat = MLMiniscopePipeline(config, settings.recordingsParentFolderSat,  settings.analysisParentFolderSat);
pipe = pipeSat; % should be true

%%

numSessions = pipe.Experiment.getNumSessions(); % not all may have worked because of RAM

% The experiment file should now contain the regular session names (not
% _cat)
for iSession = 1:numSessions %2:5 % only sessions 1,2,3 were successfull because there was enough ram
    session = pipe.Experiment.getSession(iSession);

    cattedAnalysisFolder = fullfile(settings.analysisParentFolderCat, session.getName(), pipe.Config.cell_registration.session_sfp_output_folder);
    % eg. M:\Minimice\CMG162_CA1\analysis\chengs_task_2c\s1_cat\trial_1
    
    sfpPrefix = pipe.Config.cell_registration.spatialFootprintFilenamePrefix;
    
    % There will only be one SFP (eg. sfp_001.mat)
    inputFilename = fullfile(cattedAnalysisFolder, sprintf('%s%03d.mat',sfpPrefix, 1));
    
    % Load the SFP as a way to get the number of neurons
    tmp = load(inputFilename);
    
    numNeurons = size(tmp.SFP,1); % numNeurons x video height x video width
    
    % cellreg folder (where we will create the cellRegistered_date_time
    % file
    outputFolder = fullfile(session.getAnalysisDirectory(), pipe.Config.cell_registration.session_sfp_output_folder);
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end
    
    outputFilename = fullfile( outputFolder, sprintf('cellRegistered_%s.mat', datestr(now, '20yymmdd_HHMMSS')) );
    
    numTrials = session.getNumTrials();

    cell_registered_struct = struct('cell_to_index_map', [], 'cell_scores', []);
    cell_registered_struct.cell_to_index_map = zeros(numNeurons, numTrials);
    cell_registered_struct.cell_scores = zeros(numNeurons, 1);
    
    for iNeuron = 1:numNeurons
        for iTrial = 1:numTrials
           cell_registered_struct.cell_to_index_map(iNeuron, iTrial) = iNeuron; 
        end
        cell_registered_struct.cell_scores(iNeuron) = 1.0;
    end
    
    save( outputFilename, 'cell_registered_struct' );
    
end % iSession
