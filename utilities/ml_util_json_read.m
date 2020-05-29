function [json] = ml_util_json_read(filename)
    % Make sure that the file exists
    if ~isfile( filename )
        error('The json file (%s) does not exist.', filename);
    end
    
    % Try to read the file to get its information
    try 
        json = jsondecode( fileread(filename) );
    catch ME
        error('Error encountered while reading json from (%s): %s', filename, ME.identifier)
    end
            
end % function
