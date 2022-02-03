close all
clear all
clc

%recordingsParentFolder = 'R:\chengs_task_2c\data\minimice\feature_rich\CMG087_CA1\recordings_sep';
%recordingsParentFolder = 'T:\Minimice\feature_rich\CMG129_CA1\recordings_sep';
%analysisParentFolder = strrep(recordingsParentFolder, 'recordings', 'analysis');
config = mulana_json_read(fullfile('R:\chengs_task_2c\code\ucla_miniscope\NotUSed', 'pipeline_config.json'));

%%
experimentDescriptionSepFilename = 'T:\Minimice\feature_rich\CMG129_CA1\recordings_sep\experiment_description.json';
settings = ml_miniscope_pipeline_concatenated_load(experimentDescriptionSepFilename)


%%
pipe = MLMiniscopePipeline(config, settings.recordingsParentFolderSep,  settings.analysisParentFolderSep);


%%


pipe.executeTask_AllTrials('check_data_integrity');
pipe.executeTask_AllTrials('camerasdat_create')

%%
pipe.executeTask_AllTrials('behavcam_referenceframe_create');

%%
for iSession = 1:pipe.Experiment.getNumSessions()
    session = pipe.Experiment.getSession(iSession);
    
    ml_miniscope_pipeline_concatenated_make_timestamps(session);
end


for iSession = 1:pipe.Experiment.getNumSessions()
    session = pipe.Experiment.getSession(iSession);
    ml_miniscope_pipeline_concatenated_make_scopevideos(session);
end

%% Now we have to process the concatenated session as if it is one session with one trial.
pipe = MLMiniscopePipeline(config, settings.recordingsParentFolderCat,  settings.analysisParentFolderCat);
pipe.executeTask_AllTrials('check_data_integrity');
%pipe.executeTask_AllTrials('behavcam_referenceframe_create');
pipe.executeTask_AllTrials('camerasdat_create')


%%
pipe.executeTask_AllTrials("scopecam_alignvideo");
pipe.executeTask_AllTrials("scopecam_cnmfe_run");
pipe.executeTask_AllTrials("cnfme_spatial_footprints_save_to_cellreg");
pipe.executeTask_AllTrials("cnmfe_to_neuron");

%% Now we need to separate the concatenated CNMFe results


%% Call this after the other script that create the dlc_tracks folder has been called.
pipeSat.executeTask_AllTrials('convert_dlc_to_mlbehaviourtrack');

