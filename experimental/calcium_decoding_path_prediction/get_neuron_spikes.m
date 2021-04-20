function [spike_timestamps_ms] = get_neuron_spikes(neuronDataset, scope_timestamps_ms)
    for nid = 1:neuronDataset.num_neurons
        neuron = neuronDataset.neuron(nid);
        spike_timestamps_ms{nid} = ml_cai_estimate_spikes(scope_timestamps_ms, neuron.trace_raw);
    end
end % function