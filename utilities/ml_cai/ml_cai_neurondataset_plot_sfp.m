function ml_cai_neurondataset_plot_sfp(neuronDataset, nidToShow)

    I = [];
    for nid = 1:neuronDataset.num_neurons
        sfp = neuronDataset.neuron(nid).spatial_footprint;
        J = bwperim(sfp);
        if isempty(I)
            I = J;
        else
            I = I + J;
        end
    end

    [sfpc, ri, ci] = ml_core_remove_zero_padding(neuronDataset.neuron(nidToShow).spatial_footprint);

    I(ri:ri+size(sfpc,1)-1, ci:ci+size(sfpc,2)-1) = sfpc./(max(sfpc, [], 'all')).*max(I,[], 'all');

    %h = figure('name', sprintf('neuron %d', nidToShow));

    imagesc(I)
    title(sprintf('%d neurons in total\n Showing neuron %d', neuronDataset.num_neurons, nidToShow));
    axis equal off

end % function
