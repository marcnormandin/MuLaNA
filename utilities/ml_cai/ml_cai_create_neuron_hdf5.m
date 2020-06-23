function ml_cai_create_neuron_hdf5(outputFilename, rawTraceMatrix, filtTraceMatrix, spikeMatrix, spatialFootprintMatrix)
% Lookout for the dimensions of the spikeMatrix if it comes from CNMFe

% Check the dimensions

%if size(rawTraceMatrix) == size(filtTraceMatrix) == size(spikeMatrix)

numNeurons = size(rawTraceMatrix,2);
numTimeSamples = size(rawTraceMatrix,1);

%delete( outputFilename );

fid = H5F.create(outputFilename);

for nid = 1:numNeurons
    plist = 'H5P_DEFAULT';
    
    % One group per neuron
    ng = sprintf('/neuron_%d', nid);
    gid = H5G.create(fid, ng, plist, plist, plist);
    H5G.close(gid);
end
H5F.close(fid);

h5writeatt(outputFilename, '/', 'num_neurons', numNeurons);
h5writeatt(outputFilename, '/', 'num_time_samples', numTimeSamples);
h5writeatt(outputFilename, '/', 'spatial_footprint_i', size(spatialFootprintMatrix,1));
h5writeatt(outputFilename, '/', 'spatial_footprint_j', size(spatialFootprintMatrix,2));

for nid = 1:numNeurons
    ng = sprintf('/neuron_%d', nid);
    
    % Filtered Calcium Traces
    traceRaw = rawTraceMatrix(:,nid);
    
    ds = sprintf('%s/trace_raw',ng);
    h5create(outputFilename, ds, numTimeSamples, 'Datatype', 'double');
    h5write(outputFilename, ds, traceRaw);
    
    % Filtered Calcium Traces
    traceFilt = filtTraceMatrix(:,nid);
    ds = sprintf('%s/trace_filt',ng);
    h5create(outputFilename, ds, numTimeSamples, 'Datatype', 'double');
    h5write(outputFilename, ds, traceFilt);
    
    % Spatial Footprint
    SFP = spatialFootprintMatrix(:,:,nid);
    ds = sprintf('%s/spatial_footprint',ng);
    h5create(outputFilename, ds, [size(SFP,1) size(SFP,2)], 'Datatype', 'double');
    h5write(outputFilename, ds, SFP);
    
    % Spike time series
    spikes = spikeMatrix(:,nid);
    ds = sprintf('%s/spikes',ng);
    h5create(outputFilename, ds, numTimeSamples, 'Datatype', 'double');
    h5write(outputFilename, ds, spikes);
end

fprintf('Created file: %s\n', outputFilename);

end % function
