function [neuronDataset] = ml_cai_neuron_h5_read( filename )

neuronDataset = ml_cai_core_h5_read_header( filename );
neuronDataset.neuron = ml_cai_neuron_h5_read_timeseries( filename );

end % function
