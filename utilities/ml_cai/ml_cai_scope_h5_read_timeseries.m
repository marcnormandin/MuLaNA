function [ data ] = ml_cai_scope_h5_read_timeseries( filename )
% Reads a 'scope.hdf5' file specified by the filename given in filename

h5Fields = {'frame_quality', 'framenum_local', 'framenum_global', 'timestamp_ms', 'videonum' };
matFields = h5Fields;
numFields = length(h5Fields);

for iF = 1:numFields
    fieldName = sprintf('/%s', h5Fields{iF});
    data.(matFields{iF}) = h5read( filename, fieldName );
end

% convert from uint64 to double
data.timestamp_ms = double(data.timestamp_ms);

end % function
