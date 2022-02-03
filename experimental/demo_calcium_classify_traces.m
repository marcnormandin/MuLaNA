close all
clear all
clc

trialAnalysisFolder = uigetfolder();

neuronFilename = fullfile(trialAnalysisFolder, 'neuron.hdf5');
neuronData = ml_cai_neuron_h5_read(neuronFilename);

fitParams = zeros(neuronData.num_neurons,2);

sumTrace = zeros(1, neuronData.num_time_samples);
for k = 1:neuronData.num_neurons
    nid = k;
    trace = neuronData.neuron(nid).trace_raw;
    maxTrace = max(trace,[], 'all', 'omitnan');
    trace = trace ./ maxTrace;
    
    sumTrace = sumTrace + trace;
    
    t_s = 1:numel(trace);

    [a,b, ~] = ml_util_medianmedian_linearfit(t_s,trace);

    fitParams(nid,:) = [a, b];
end


%% Plot traces that are not good
close all

aMean = nanmean(fitParams(:,1));
aStd = nanstd(fitParams(:,1));

bMean = nanmean(fitParams(:,2));
bStd = nanstd(fitParams(:,2));

bad = (abs(fitParams(:,1)-aMean) > aStd) | (abs(fitParams(:,2)-bMean) > bStd);

badCellIds = find(bad == 1);
for k = 1:length(badCellIds)
    cid = badCellIds(k);
    
    trace = neuronData.neuron(cid).trace_raw;
    maxTrace = max(trace,[], 'all', 'omitnan');
    trace = trace ./ maxTrace;
    
    figure
    plot(t_s, trace, 'k-')
    hold on
    plot(t_s, fitParams(cid,1) + fitParams(cid,2)*t_s, 'r-', 'linewidth', 2)
    title(sprintf('Cell %d has a bad baseline', cid))
end

%% Good ones?
close all

aMean = nanmean(fitParams(:,1));
aStd = nanstd(fitParams(:,1));

bMean = nanmean(fitParams(:,2));
bStd = nanstd(fitParams(:,2));

bad = (abs(fitParams(:,1)-aMean) > aStd) | (abs(fitParams(:,2)-bMean) > bStd);

goodCellIds = find(bad == 0);
for k = 1:length(goodCellIds)
    cid = goodCellIds(k);
    
    trace = neuronData.neuron(cid).trace_raw;
    maxTrace = max(trace,[], 'all', 'omitnan');
    trace = trace ./ maxTrace;
    
    figure
    plot(t_s, trace, 'k-')
    hold on
    plot(t_s, fitParams(cid,1) + fitParams(cid,2)*t_s, 'r-', 'linewidth', 2)
    title(sprintf('Cell %d has a good baseline', cid))
end
