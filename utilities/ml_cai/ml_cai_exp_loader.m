%% This is the improved loader for an experiment.
%  It allows us to associate the information such as digs, contexts,
%  and whether or not to skip a particular trials dataset (for instances
%  such as corruption, or that we have darkframes, etc.

%sessionsRecordingParentFolder = pwd;
%sessionsAnalysisParentFolder = fullfile(pwd, '../../temp');
%expDescFilename = fullfile(sessionsRecordingParentFolder, 'experiment_description.json');

function [exp] = ml_cai_exp_loader(expDescFilename, sessionsRecordingParentFolder)

    exp = jsondecode(fileread(expDescFilename));

    % All the session records will have this filename
    MLCALPIPE_SESSION_RECORD_FILENAME = 'session_record.json';


    numSessionFolders = length(exp.session_folders);
    for iSession = 1:numSessionFolders
        % See if the session parent folder actually exists
        sf = fullfile(sessionsRecordingParentFolder, exp.session_folders{iSession});
        if ~isfolder(sf)
            error('The session folder (%s) does not exist.', sf);
        end

        % See if the session record exists
        srfn = fullfile(sf, MLCALPIPE_SESSION_RECORD_FILENAME);
        if ~isfile(srfn)
            error('The session record file (%s) does not exist.')
        end

        % Load the session record
        sr = jsondecode(fileread(fullfile(srfn)));

        % Validate the array lengths, which all must be the same
        n = length(sr.trial_info.sequence_num);
        if length(sr.trial_info.contexts) ~= n || length(sr.trial_info.use) ~= n || length(sr.trial_info.digs) ~= n || length(sr.trial_info.folder) ~= n
            error('Invalid array lengths for session (%s). All must be the same length:\n\tsequence_num: %d\n\tcontexts: %d\n\tuse: %d\n\tdigs: %d\n\tfolder: %d\n', ...
                srfn, length(sr.trial_info.sequence_num), length(sr.trial_info.contexts), length(sr.trial_info.use), ...
                length(sr.trial_info.digs), length(sr.trial_info.folder));
        end

        % Check that each trial folder of the session which is desired to be used actually exists
        useIndices = find(sr.trial_info.use == 1);
        for iUseIndices = 1:length(useIndices)
            tf = fullfile(sf, sr.trial_info.folder{useIndices(iUseIndices)});
            if ~isfolder(tf)
                error('The trial record folder (%s) does not exist.\n', tf);
            end
        end

        % Add the session record
        exp.session{iSession} = sr;
    end
    exp.numSessions = length(exp.session);
end % function
