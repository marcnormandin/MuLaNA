function [scopeDataset ] = ml_cai_scope_h5_read(fn)
% Reads a 'scope.hdf5' file specified by the filename given in fn

scopeDataset = ml_cai_core_h5_read_header( fn );
scopeArrays = ml_cai_scope_h5_read_timeseries( fn );

arrayNames = fields(scopeArrays);
numArrays = length(arrayNames);
for iF = 1:numArrays
    arrayName = arrayNames{iF};
    scopeDataset.(arrayName) = scopeArrays.(arrayName);
end

end % function
