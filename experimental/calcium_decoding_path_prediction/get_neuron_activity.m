function P = get_neuron_activity(T, binIndex, neuronId)
    P = T.(sprintf('neuron_%d', neuronId))(ismember(T.ind, binIndex));
end