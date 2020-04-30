function [ neuron, numNeurons, numTimesamples ] = ml_cai_neuron_h5_read_timeseries(ndf)
% Reads a 'neuron.hdf5' file specified by the filename given in ndf

numNeurons = h5readatt(ndf, '/', 'num_neurons');
numTimesamples = h5readatt(ndf, '/', 'num_time_samples');

ndfFields = {'spatial_footprint', 'spikes', 'trace_filt', 'trace_raw'};
matFields = ndfFields;
numFields = length(ndfFields);

c = cell(length(matFields),1);
s = cell2struct(c,matFields);
neuron = repmat(s, numNeurons, 1);

for iN = 1:numNeurons
    for iF = 1:numFields
        fstr = sprintf('/neuron_%d/%s', iN, ndfFields{iF});
        neuron(iN).(matFields{iF}) = h5read(ndf, fstr);
    end
end

end % function
