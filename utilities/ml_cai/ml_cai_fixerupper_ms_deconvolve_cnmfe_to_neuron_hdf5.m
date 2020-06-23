function [deconv_options] = ml_cai_fixerupper_ms_deconvolve_cnmfe_to_neuron_hdf5(outputFilename, ms, deconv_options_0)

numNeurons = ms.numNeurons;
numTimeSamples = size(ms.FiltTraces,1);

% The one found after deconvolving, not the one already found
% since we need it to make the found spike series
filtTraceMatrix = nan(numTimeSamples, numNeurons);
spikeMatrix = nan(numTimeSamples, numNeurons);

rawTraceMatrix = ms.RawTraces;
spatialFootprintMatrix = ms.SFPs;

for nid = 1:numNeurons
    [traceFilt, spikes, deconv_options] = ml_cai_deconvolve_cnmfe_raw_trace(deconv_options_0, rawTraceMatrix(:,nid));
    filtTraceMatrix(:,nid) = traceFilt;
    spikeMatrix(:,nid) = spikes;
end

ml_cai_create_neuron_hdf5(outputFilename, rawTraceMatrix, filtTraceMatrix, spikeMatrix, spatialFootprintMatrix);

end % function
