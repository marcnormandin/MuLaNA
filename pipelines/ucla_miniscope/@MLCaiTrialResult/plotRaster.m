function rasterPlot(obj)
    scope_timestamps_ms = obj.getScopeTimestampsMs();

    tm = ceil(scope_timestamps_ms(end)/1000);
    edges_s = linspace(0, tm, tm);

    raster = zeros(obj.neuronData.num_neurons, length(edges_s)-1);
    for iN = 1:obj.neuronData.num_neurons
        t_s = [obj.neuronData.neuron(iN).calciumEvents(:).timestamps_begin_ms] / 1000.0;
        t_s_binned = discretize(t_s, edges_s);

        tvalues = [obj.neuronData.neuron(iN).calciumEvents(:).integrated_trace_filt];
        raster(iN, t_s_binned) = tvalues;
    end

    %figure
    imagesc(raster)
    xlabel('Time, t [s]')
    ylabel('Neuron #')
    title('Calcium Events')
    %colormap gray
    colormap jet
end % function
