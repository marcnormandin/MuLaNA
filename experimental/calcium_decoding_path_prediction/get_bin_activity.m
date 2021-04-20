function Y = get_bin_activity(T, binIndex, n1, n2)
    Y1 = get_neuron_activity(T, binIndex, n1);
    Y2 = get_neuron_activity(T, binIndex, n2);
    
    % Remove unusable value
    i1 = isnan(Y1);
    i2 = isnan(Y2);
    ibad = find(i1 | i2);
    Y1(ibad) = [];
    Y2(ibad) = [];
    Y(:,1) = Y1;
    Y(:,2) = Y2;
end