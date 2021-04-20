function [experiment] = mltp_create_session_folders( obj, recordingsParentFolder, analysisParentFolder, experimentDescriptionFilename )
            VERBOSE = obj.isVerbose();
            if VERBOSE
                 fprintf('Creating the analysis folder structure (if it does not exist).\n');
            end
            
            if ~isfile( experimentDescriptionFilename )
                error('The file (%s) does not exist.', experimentDescriptionFilename );
            end
            
            experiment.info = jsondecode(fileread( experimentDescriptionFilename ));
            experiment.subjectName = experiment.info.animal;
            experiment.dataset = experiment.info.experiment;

            % Create the analysis folder if it doesn't already exist
            if ~exist(analysisParentFolder,'dir')
                if VERBOSE
                    fprintf('Creating analysis folder (%s) ... ', analysisParentFolder);
                end
                mkdir(analysisParentFolder);
                if VERBOSE
                    fprintf('done!\n');
                end
            end

            numSessions = length(experiment.info.session_folders);
            session = cell(numSessions,1);

            for iSession = 1:numSessions

                sessionFolder = fullfile(recordingsParentFolder, experiment.info.session_folders{iSession});
                
                session{iSession}.rawFolder = sessionFolder;
                session{iSession}.name = experiment.info.session_folders{iSession};
                
                recordFilename = fullfile(sessionFolder, "session_record.json"); 
                
                % Create a default record file if one doesn't exist.
                % This can aid the user if they forget to add it.
                if ~isfile(recordFilename)
                    fprintf('Creating default record.json for %s\n', session{iSession}.name);

                    defaultRecordName = experiment.info.session_folders{iSession};
                    defaultRecordDate = "unknown";
                    
                    % We need to load the nvt to figure out the number of
                    % trials (which is slow)
                    nvtFullFilename = fullfile(sessionFolder, obj.config.nvt_filename);
                    defaultRecordNumTrialsTotal = ml_nlx_nvt_get_num_trials(nvtFullFilename, obj.config.nvt_file_trial_separation_threshold_s);
                    defaultRecordNumContexts = experiment.info.num_contexts;
                    
                    MLSessionRecord.createDefaultFile(...
                        defaultRecordNumTrialsTotal, defaultRecordNumContexts, ...
                        defaultRecordName, defaultRecordDate, recordFilename);
                    
                    fprintf('Default record.json saved to: %s\n', recordFilename);
                end
                recordData = fileread( recordFilename );
                session{iSession}.record = jsondecode( recordData );
                
                % Refactor to using the class
                session{iSession}.sessionRecord = MLSessionRecord( fullfile(session{iSession}.rawFolder, 'session_record.json') );
                
                % Get the tfile names
                fl = dir(fullfile(session{iSession}.rawFolder, 'TT*.t'));
                tfiles = { fl.name };
                
                session{iSession}.num_tfiles = length(tfiles);
                session{iSession}.tfiles_filename_prefixes = cell(1, session{iSession}.num_tfiles);
                session{iSession}.tfiles_filename_full = cell(1, session{iSession}.num_tfiles);
                if length(session{iSession}.tfiles_filename_prefixes) > 0
                    session{iSession}.hasSingleUnits = true;
                else
                    session{iSession}.hasSingleUnits = false;
                end
                
                for iFile = 1:length(tfiles)
                    session{iSession}.tfiles_filename_full{iFile} = tfiles{iFile};
                    tmp = split(session{iSession}.tfiles_filename_full{iFile},'.');
                    session{iSession}.tfiles_filename_prefixes{iFile} = tmp{1}; 
                end
                        
                
                % Create the analysis session folder if it doesn't already exist
                analysisSessionFolder = fullfile(analysisParentFolder, experiment.info.session_folders{iSession});
                session{iSession}.analysisFolder = analysisSessionFolder;

                if ~exist(analysisSessionFolder,'dir')
                    if VERBOSE
                        fprintf('Creating analysis session folder (%s) ... ', analysisSessionFolder);
                    end
                    mkdir(analysisSessionFolder);
                    if VERBOSE
                        fprintf('done!\n');
                    end
                end
            end

            experiment.numSessions = numSessions;
            experiment.session = session;

            if VERBOSE
                 fprintf('Finished creating the analysis folder structure.\n');
            end
            
        end % function
