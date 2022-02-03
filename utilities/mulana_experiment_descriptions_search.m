function [validDescriptions, invalidDescriptions] = mulana_experiment_descriptions_search(SEARCH_FOLDER)
    % Search all directory and all subdirectories for
    % 'experiment_description.json' and store their data in an array.

    experimentDescriptions = dir(fullfile(SEARCH_FOLDER, '**', 'experiment_description.json')); 
    validDescriptions = [];
    invalidDescriptions = [];

    for iExp = 1:length(experimentDescriptions)
        edFilename = fullfile(experimentDescriptions(iExp).folder, experimentDescriptions(iExp).name);

        % Try to read the file to get its information
        if ~isfile( edFilename )
            error('The session record (%s) does not exist.', edFilename);
        end
        edjson = [];
        try 
            %edjson = jsondecode( fileread(edFilename) );
            edjson = mlgp_read_experiment_description_json(edFilename);
        catch ME
            fprintf('Error encountered while reading from (%s): %s\n', edFilename, ME.identifier)
            l = length(invalidDescriptions)+1;
            invalidDescriptions(l).fullFilename = edFilename;
            invalidDescriptions(l).folder = experimentDescriptions(iExp).folder;
            continue; % skip this file
        end
        k = length(validDescriptions)+1;
        % If we loaded it fine, then store it for returning
        validDescriptions(k).fullFilename = edFilename;
        validDescriptions(k).folder = experimentDescriptions(iExp).folder;
        validDescriptions(k).json = edjson;
    end % iExp

end % function
