% This is a one-off script. It was written to process the concatenated
% CNFMe into the separate trial results

%% READ MEE
% Run this only when the experiment.json is referencing the UNCATTED
% session names or it will overwrite what we want!!!

close all
clear all
clc

config = mulana_json_read(fullfile('R:\chengs_task_2c\code\ucla_miniscope\NotUSed', 'pipeline_config.json'));
experimentDescriptionSepFilename = 'T:\Minimice\feature_rich\CMG129_CA1\recordings_sep\experiment_description.json';

settings = ml_miniscope_pipeline_concatenated_load(experimentDescriptionSepFilename);
%pipeSep = MLMiniscopePipeline(config, settings.recordingsParentFolderSep,  settings.analysisParentFolderSep);
pipeSat = MLMiniscopePipeline(config, settings.recordingsParentFolderSat,  settings.analysisParentFolderSat);

% session id to process
%% Copy the analysis_sep which should contain data like the cameras dat files into the analysis_sat folder
copyfile(settings.analysisParentFolderSep, settings.analysisParentFolderSat);


%% Copy the spatial footprints into each trials directory 
numSessions = pipeSat.Experiment.getNumSessions();
for iSession = 1:numSessions
    session = pipeSat.Experiment.getSession(iSession);
    sessionName = session.getName();
    
    % Get the catted analysis folder
    cattedAnalysisTrialFolder = fullfile(settings.analysisParentFolderCat, sessionName, 'trial_1');
    % Get the spatil footprings for the catted session which will be the
    % same for each trial when split
    sfpSourceFilename = fullfile(cattedAnalysisTrialFolder, sprintf('%s.mat',config.cell_registration.spatialFootprintFilenamePrefix));
    if ~isfile(sfpSourceFilename)
        error('Unable to find source file (%s).', sfpSourceFilename);
    end
    
    %session = pipe.Experiment.getSession(iSession);
    numTrials = session.getNumTrials();
    for iTrial = 1:numTrials
        trial = session.getTrial(iTrial);
        
        if ~exist(trial.getAnalysisDirectory(), 'dir')
            mkdir(trial.getAnalysisDirectory());
        end
        
        sfpDestFilename = fullfile(trial.getAnalysisDirectory(), sprintf('%s.mat', config.cell_registration.spatialFootprintFilenamePrefix));
        if isfile(sfpDestFilename)
            delete(sfpDestFilename);
        end
        fprintf('Copying (%s) to (%s) ... ', sfpSourceFilename, sfpDestFilename);
        copyfile( sfpSourceFilename, sfpDestFilename );
        fprintf('done!\n');
    end
end

%% This is the concatenated data
numSessions = pipeSat.Experiment.getNumSessions();
for iSession = 1:numSessions
    session = pipeSat.Experiment.getSession(iSession);
    sessionName = session.getName();

    % Catted cnmfe location
    cattedAnalysisTrialFolder = fullfile(settings.analysisParentFolderCat, sessionName, 'trial_1');
    neuronDataset = ml_cai_neuron_h5_read( fullfile(cattedAnalysisTrialFolder, 'neuron.hdf5') );
    numNeurons = neuronDataset.num_neurons;
    tmp = load(fullfile(cattedAnalysisTrialFolder, 'cnmfe.mat'));
    cnmfe = tmp.cnmfe;

    %
    %session = pipe.Experiment.getSession(iSession);
    numTrials = session.getNumTrials();
    numTrialFrames = zeros(1, numTrials);
    for iTrial = 1:numTrials
        trial = session.getTrial(iTrial);
        % We need to get the number of scope frames for each trial
        scopeDataset = ml_cai_scope_h5_read(fullfile(trial.getAnalysisDirectory(), 'scope.hdf5') );
        numFrames = scopeDataset.num_frames;
        numTrialFrames(iTrial) = numFrames;
    end

    %
    % Now we need to separate the single concantenated neuron data into
    % individual neuron files (1 per trial)
    numPrevFrames = 0;
    for iTrial = 1:numTrials
        trial = session.getTrial(iTrial);

        i = numPrevFrames + 1;
        j = i + numTrialFrames(iTrial)-1;
        indices = i:j;

        numPrevFrames = numPrevFrames + numTrialFrames(iTrial);

        outputFilename = fullfile(trial.getAnalysisDirectory(), 'neuron.hdf5');
        if isfile(outputFilename)
           delete(outputFilename)
        end
        rawTraceMatrix = cnmfe.RawTraces(indices,:);
        filtTraceMatrix = cnmfe.FiltTraces(indices,:);
        spikeMatrix = cnmfe.neuron.S(:, indices)'; % take transponse because that is what the hdf5 needs (time x cell)
        spatialFootprintMatrix = cnmfe.SFPs;

        ml_cai_create_neuron_hdf5(outputFilename, rawTraceMatrix, filtTraceMatrix, spikeMatrix, spatialFootprintMatrix)
    end
end % function

%%
