%path = '/work/muzziolab/PROJECTS/two_contexts_CA1/tetrodes/recordings/feature_rich/AK42_CA1';



%%
path='/work/muzziolab/DATA/Minimice/CMG132_CA1/recordings/chengs_task_2c';
trialFolders = ml_cai_io_trialfolders_find(fullfile(path, 's1'))

%%
clc

experiment = MLExperimentBuilder.buildFromJson(path, '/work/muzziolab/analysis_test/CMG132_CA1');

for iSession = 1:experiment.getNumSessions()
    s = experiment.getSession(iSession);
    for iTrial = 1:s.getNumTrials()
        t = s.getTrial(iTrial);
        fprintf('S%d (%s), S%d, %s, Context %d ', iSession, s.getName(), iTrial, t.getName(), t.getContextId());
        if ~t.isEnabled()
            fprintf('\tDISABLED\t');
        end
        
        fprintf('%s\t%s', t.getTrialDirectory(), t.getAnalysisDirectory());
        fprintf('\n');
    end
end

configFilename = fullfile(pwd, 'pipeline_config.json');
recordingsParentFolder = '/work/muzziolab/DATA/CMG132_CA1/recordings/chengs_task_2c';
analysisParentFolder = '../analysis/CMG132_CA1';

pipe = MLPipeline2(config, recordingsParentFolder,  analysisParentFolder)

%pipe = MLPipeline2(experiment);
%obj.availablePerSessionTasks('dummy_session_task') = @obj.dummy_session_task;
