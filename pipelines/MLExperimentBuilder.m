classdef MLExperimentBuilder < handle
    properties (Constant)
        ExperimentDescriptionFilename = 'experiment_description.json';
        SessionRecordFilename = 'session_record.json';
        
    end % properties
    
    methods (Static)
        %%
        function [experiment] = buildFromJson(config, sessionsParentDirectory, analysisParentDirectory)
            expJsonFilename = fullfile(sessionsParentDirectory, MLExperimentBuilder.ExperimentDescriptionFilename);
            if ~isfile(expJsonFilename)
                error('The required file (%s) does not exist.', expJsonFilename);
            end
            
            % Read the experiment description json file
            expJson = mlgp_read_experiment_description_json(expJsonFilename);
 
            % Switch based on the type because we determine trials
            % differently based on the apparatus
            if strcmpi(expJson.apparatus_type, 'neuralynx_tetrodes')
                experiment = MLExperimentBuilder.buildFromJsonNeuralyxTetrodes(config, expJson, sessionsParentDirectory, analysisParentDirectory);
            elseif strcmpi(expJson.apparatus_type, 'ucla_miniscope')
                experiment = MLExperimentBuilder.buildFromJsonUclaMiniscope(config, expJson, sessionsParentDirectory, analysisParentDirectory);
            else
                error('Unable to build experiment for the ''apparatus_type'' (%s). It must be ''neuralynx_tetrodes'', or ''ucla_miniscope''.', expJson.apparatus_type);
            end
        end
        
        

        %% TETRODES
        function [experiment] = buildFromJsonNeuralyxTetrodes(config, expJson, sessionsParentDirectory, analysisParentDirectory)
            numSessions = length(expJson.session_folders);
            sessions = MLTetrodeSession.empty;
            numContexts = expJson.num_contexts;
            for iSession = 1:numSessions
                sessionDirectory = fullfile(sessionsParentDirectory, expJson.session_folders{iSession});
                if ~exist(sessionDirectory, 'dir')
                    error('The session recording directory (%s) does not exist. Remove name from experiment_description or create it.', sessionDirectory);
                end
                
                sessionAnalysisDirectory = fullfile(analysisParentDirectory, expJson.session_folders{iSession});
                
                % Check if the session record exists, and if it doesn't
                % then we create a default one.
                srFilename = fullfile(sessionDirectory, MLExperimentBuilder.SessionRecordFilename);
                if ~isfile(srFilename)
                    sessionName = expJson.session_folders{iSession};
                    MLExperimentBuilder.createDefaultSessionRecordNeuralynxTetrodes(expJson, sessionDirectory, sessionName);
                end
                
                sr = MLSessionRecord( srFilename );
                trials = MLTrial.empty;
                numTrials = sr.getNumTrials();
                tri = sr.getTrialsInfo(); % Get the trial info for every trial
                dateString = sr.getDate();
                
                for iTrial = 1:numTrials
                    trialId = tri(iTrial).trialId;
                    
                    name = sprintf('T%d', trialId);
                    
                    timeString = sprintf('%d', iTrial);
                    
                    trialDirectory = sessionDirectory;
                    
                    trialAnalysisDirectory = fullfile(sessionAnalysisDirectory, sprintf('trial_%d', trialId));
                    
                    trials(iTrial) = MLTrial(...
                        name, tri(iTrial).sliceId, tri(iTrial).trialId, tri(iTrial).context, expJson.has_digs, tri(iTrial).digs, tri(iTrial).use==1, ...
                        trialDirectory, trialAnalysisDirectory, ...
                        dateString, timeString);
                end
                sessions(iSession) = MLTetrodeSession(config, sr, sr.getName(), sr.getDate(), trials, sessionDirectory, sessionAnalysisDirectory);
            end
            
            experiment = MLTetrodeExperiment( ...
                expJson.animal, expJson.imaging_region, expJson.experiment, expJson.arena, numContexts, sessions, sessionsParentDirectory, analysisParentDirectory, ...
                expJson.mclust_tfile_bits, expJson.nvt_file_trial_separation_threshold_s, expJson.nvt_filename);
        end % buildFromJson
        
        function createDefaultSessionRecordNeuralynxTetrodes(expJson, sessionDirectory, sessionName)
            fprintf('Creating default record.json for %s\n', sessionName);

            recordFilename = fullfile(sessionDirectory, MLExperimentBuilder.SessionRecordFilename);
            defaultRecordName = sessionName;
            defaultRecordDate = "unknown";

            % We need to load the nvt to figure out the number of
            % trials.

            nvtFullFilename = fullfile(sessionDirectory, expJson.nvt_filename);
            if ~isfile(nvtFullFilename)
                error('The required file (%s) does not exist.', nvtFullFilename);
            end
            
            defaultRecordNumTrialsTotal = ml_nlx_nvt_get_num_trials(nvtFullFilename, expJson.nvt_file_trial_separation_threshold_s);
            

            defaultRecordNumContexts = expJson.num_contexts;

            MLSessionRecord.createDefaultFile(...
            defaultRecordNumTrialsTotal, defaultRecordNumContexts, ...
            defaultRecordName, defaultRecordDate, recordFilename, []);

            fprintf('Default record.json saved to: %s\n', recordFilename);
        end
        
                
                
                
        
        %% MINISCOPE
        function [experiment] = buildFromJsonUclaMiniscope(config, expJson, sessionsParentDirectory, analysisParentDirectory)
            numSessions = length(expJson.session_folders);
            sessions = MLMiniscopeSession.empty;
            numContexts = expJson.num_contexts;
            
            for iSession = 1:numSessions
                sessionName = expJson.session_folders{iSession};
                sessionDirectory = fullfile(sessionsParentDirectory, sessionName);
                if ~exist(sessionDirectory, 'dir')
                    error('The session recording directory (%s) does not exist. Remove name from experiment_description or create it.', sessionDirectory);
                end
                
                sessionAnalysisDirectory = fullfile(analysisParentDirectory, sessionName);
                
                % Check if the session record exists, and if it doesn't
                % then we create a default one.
                srFilename = fullfile(sessionDirectory, MLExperimentBuilder.SessionRecordFilename);
                if ~isfile(srFilename)
                    MLExperimentBuilder.createDefaultSessionRecordUclaMiniscope(expJson, sessionDirectory, sessionName);
                end
                
                sr = MLSessionRecord( srFilename );
                trials = MLTrial.empty;
                numTrials = sr.getNumTrials();
                tri = sr.getTrialsInfo(); % Get the trial info for every trial
                dateString = sr.getDate();
                for iTrial = 1:numTrials
                    trialId = tri(iTrial).trialId;
                    sliceId = tri(iTrial).sliceId;
                    
                    name = sprintf('T%d', trialId);
                        % Load the json directory to get the trial folder
                        % names
                        sjson = ml_util_json_read(fullfile(sessionDirectory, MLExperimentBuilder.SessionRecordFilename));
                        trialDirectory = fullfile(sessionDirectory, sjson.trial_info.folders{sliceId});
        
                    timeString = sjson.trial_info.folders{sliceId};
                    
                    trialAnalysisDirectory = fullfile(sessionAnalysisDirectory, sprintf('trial_%d', trialId));
                    
                    trials(iTrial) = MLTrial(...
                        name, tri(iTrial).sliceId, tri(iTrial).trialId, tri(iTrial).context, expJson.has_digs, tri(iTrial).digs, tri(iTrial).use==1, ...
                        trialDirectory, trialAnalysisDirectory, ...
                        dateString, timeString);
                end
                sessions(iSession) = MLMiniscopeSession(config, sr, sr.getName(), sr.getDate(), trials, sessionDirectory, sessionAnalysisDirectory);
            end
            
            experiment = MLExperiment( ...
                expJson.animal, expJson.imaging_region, expJson.experiment, expJson.arena, numContexts, sessions, sessionsParentDirectory, analysisParentDirectory );
        end % buildFromJson
        

        
        function createDefaultSessionRecordUclaMiniscope(expJson, sessionDirectory, sessionName)
            fprintf('Creating default record.json for %s\n', sessionName);

            recordFilename = fullfile(sessionDirectory, MLExperimentBuilder.SessionRecordFilename);
            defaultRecordName = sessionName;
            defaultRecordDate = "unknown";

            % Get the subdirectories that have the UCLA trial format
            % H_#_M#_S#
            trialFolders = ml_cai_io_trialfolders_find(sessionDirectory);

            defaultRecordNumTrialsTotal = length(trialFolders);
            defaultRecordNumContexts = expJson.num_contexts;

            MLSessionRecord.createDefaultFile(...
            defaultRecordNumTrialsTotal, defaultRecordNumContexts, ...
            defaultRecordName, defaultRecordDate, recordFilename, {trialFolders.name});

            fprintf('Default record.json saved to: %s\n', recordFilename);
        end
    end % methods
end % classdef