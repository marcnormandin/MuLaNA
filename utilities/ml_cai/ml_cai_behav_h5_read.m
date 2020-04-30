function [behavDataset ] = ml_cai_behav_h5_read(fn)
% Reads a 'behav.hdf5' file specified by the filename given in fn

behavDataset = ml_cai_core_h5_read_header( fn );
behavArrays = ml_cai_behav_h5_read_timeseries( fn );

arrayNames = fields(behavArrays);
numArrays = length(arrayNames);
for iF = 1:numArrays
    arrayName = arrayNames{iF};
    behavDataset.(arrayName) = behavArrays.(arrayName);
end

end % function
