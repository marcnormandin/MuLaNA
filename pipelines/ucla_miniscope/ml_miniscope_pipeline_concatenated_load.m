function [settings] = ml_miniscope_pipeline_concatenated_load(experimentDescriptionSepFilename)
    % The data is normally saved as separate trials. This points to the folder
    % containing the experiment_description.json for the separate trials. Point
    % this to the mouses parent directory that we will make a concatenated
    % version for.
    %experimentDescriptionSepFilename = 'R:\chengs_task_2c\minimice\feature_rich\CMG129_CA1\recordings_sep\experiment_description.json';

    if ~isfile(experimentDescriptionSepFilename)
        error('The specified file does not exist (%s).\n', experimentDescriptionSepFilename);
    end

    [recordingsParentFolderSep, expFilenamePrefix, expFilenameSuffix] = fileparts(experimentDescriptionSepFilename);
    % Check if the folder ends in '_sep' and contains the word 'recordings'
    if ~contains(recordingsParentFolderSep, 'recordings') || ~contains(recordingsParentFolderSep, '_sep')
        error('The folder containing "experiment_description.json" must be "recordings_sep".');
    end

    % Specify the folder name for the concatenated data.
    recordingsParentFolderCat = strrep(recordingsParentFolderSep, '_sep', '_cat');
    recordingsParentFolderSat = recordingsParentFolderSep; %strrep(recordingsParentFolderCat, '_sep', '_sat');

    analysisParentFolderSep = strrep(recordingsParentFolderSep, 'recordings', 'analysis');
    analysisParentFolderCat = strrep(recordingsParentFolderCat, 'recordings', 'analysis');


    analysisParentFolderSat = strrep(recordingsParentFolderSep, 'recordings', 'analysis');
    analysisParentFolderSat = strrep(analysisParentFolderSat, '_sep', '_sat');


    % If the folder does not exist, then create it.
    if ~exist(analysisParentFolderSep, 'dir')
        mkdir(analysisParentFolderSep);
        fprintf('Created new directory (%s).\n', analysisParentFolderSep);
    end

    if ~exist(recordingsParentFolderCat, 'dir')
        mkdir(recordingsParentFolderCat);
        fprintf('Created new directory (%s).\n', recordingsParentFolderCat);
    end

    if ~exist(analysisParentFolderCat, 'dir')
        mkdir(analysisParentFolderCat);
        fprintf('Created new directory (%s).\n', analysisParentFolderCat);
    end

    % Note that we don't need a recordingsParentFolderSat because it uses the
    % same data as the separate trials.

    if ~exist(analysisParentFolderSat, 'dir')
        mkdir(analysisParentFolderSat);
        fprintf('Created new directory (%s).\n', analysisParentFolderSat);
    end


    % We will create a new experiment_description.json file from the original
    % one (just make a copy) and it will be saved in the new parent folder
    % directory for the concatenated data.
    experimentDescriptionCatFilename = fullfile(recordingsParentFolderCat, sprintf('%s%s', expFilenamePrefix, expFilenameSuffix) );

    % Copy the original experiment description to the new folder
    if isfile(experimentDescriptionCatFilename)
        delete(experimentDescriptionCatFilename);
        fprintf('Deleted file (%s).\n', experimentDescriptionCatFilename);
    end
    copyfile(experimentDescriptionSepFilename, experimentDescriptionCatFilename);
    fprintf('Copied (%s) to (%s).\n', experimentDescriptionSepFilename, experimentDescriptionCatFilename);

    settings.recordingsParentFolderSep = recordingsParentFolderSep;
    settings.recordingsParentFolderCat = recordingsParentFolderCat;
    settings.recordingsParentFolderSat = recordingsParentFolderSat;

    settings.analysisParentFolderSep = analysisParentFolderSep;
    settings.analysisParentFolderCat = analysisParentFolderCat;
    settings.analysisParentFolderSat = analysisParentFolderSat;

end % function
