close all
clear all
clc
fclose('all')

recordingsParentFolder = '/work/muzziolab/PROJECTS/two_contexts_CA1/miniscope/recordings/feature_rich/CMG129_CA1';
analysisParentFolder = strrep(recordingsParentFolder, 'recordings', 'analysis');
config = mulana_json_read('/work/muzziolab/PROJECTS/two_contexts_CA1/miniscope/sourcecode/pipeline_config.json');
pipe = MLMiniscopePipeline(config, recordingsParentFolder,  analysisParentFolder);

% Define the ROI for all trials of a given session
for iSession = 1:pipe.Experiment.getNumSessions()
    session = pipe.Experiment.getSession(iSession);
    for iTrial = 1:session.getNumTrials()
        pipe.executeTrialTaskByIndices('behavcam_roi_create', iSession, iTrial)
    end
end

