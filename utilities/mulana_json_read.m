function [json] = mulana_json_read(filename)
    % Read in the json file
    if ~isfile( filename )
        error('Cannot read the json file (%s), as it does not exist.', filename);
    end
    try 
        json = jsondecode( fileread(filename) );
    catch ME
        error('Error encountered while reading json from (%s): %s', filename, ME.identifier)
    end
end % function
