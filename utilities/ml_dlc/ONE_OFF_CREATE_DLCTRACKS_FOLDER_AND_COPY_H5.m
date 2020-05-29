% THIS IS A ONE-OFF!!!
% close all
% clear all
% clc

% cfg = jsondecode(fileread(fullfile(pwd, 'pipeline_config.json')));
% pipe = MLCalciumImagingPipeline( cfg, ...
%     pwd, '../../analysis/chengs_task_2c' );


mainDir = 'M:/Minimice/CMG154_RSC/recordings/chengs_task_2c';
cfg = jsondecode(fileread(fullfile(pwd, 'pipeline_config.json')));
pipe = MLCalciumImagingPipeline( cfg, mainDir, strrep(mainDir, 'recordings', 'analysis') );

experimentRecordingsParentFolder = pipe.experimentParentFolder;
experimentTracksParentFolder = strrep(experimentRecordingsParentFolder, "recordings", "dlc_tracks");

% Make a copy of the directory tree, but under the tracks parent
for iSession = 1:pipe.experiment.numSessions
    session = pipe.experiment.session{iSession};
    for iTrial = 1:session.numTrials
        trial = session.trial{iTrial};
        tdataFolder = trial.rawFolder;
        
        ttrackFolder = strrep(tdataFolder, "recordings", "dlc_tracks");
        if ~isfolder(ttrackFolder)
            mkdir(ttrackFolder);
        end
        
        trialDLCFolder = tdataFolder;
        
        % Get list of the h5 files to be moved
        files = dir(fullfile(trialDLCFolder, 'behavCam*DLC_resnet50_CMG089_CA1_EPOCH_2_EARSJan25shuffle1_1030000.h5'));
        for iFile = 1:length(files)
            fn = files(iFile).name;
            % remove the specifics so the follow-up code can be more
            % general
            fn2 = strrep(fn, 'DLC_resnet50_CMG089_CA1_EPOCH_2_EARSJan25shuffle1_1030000.h5', '_DLC.h5');
            copyfile(fullfile(trialDLCFolder, fn), fullfile(ttrackFolder, fn2));
        end
    end
end
