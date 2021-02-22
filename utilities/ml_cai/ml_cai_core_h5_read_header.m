function [header] = ml_cai_core_h5_read_header( filename )

if ~isfile(filename)
    error('The file (%s) does not exist.', filename);
end

s = h5info( filename );

% output
header = {};

% Get the attribute names in the root element
attribNames = {s.Attributes(:).Name};
numAttributes = length(attribNames);

% Read each attribute value
for iA = 1:numAttributes
    aname = attribNames{iA};
    header.(aname) = h5readatt( filename, '/', aname );
end

end % function
