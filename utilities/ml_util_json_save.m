function ml_util_json_save(data, jsonFilename)
% Save a struct as JSON-formatted text, and make it pretty

jsonTxt = jsonencode(data);

% Make it prettier
jsonTxt = strrep(jsonTxt, ',', sprintf(',\n'));
jsonTxt = strrep(jsonTxt, '[{', sprintf('[\n{\n'));
jsonTxt = strrep(jsonTxt, '}]', sprintf('\n}\n]'));

fid = fopen(jsonFilename, 'w');
if fid == -1
    error('Unable to create the file (%s) for writing.', jsonFilename);
end
fwrite(fid, jsonTxt, 'char');
fclose(fid);

end % function
