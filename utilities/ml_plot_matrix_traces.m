function ml_plot_matrix_traces(x, traceMatrix)
% Each row of the traceMatrix should be the trace of a single cell.

numNeurons = size(traceMatrix,1);
numTimeSamples = size(traceMatrix,2);

for iNeuron = 1:numNeurons
    %x = 1:numTimeSamples;
    y = traceMatrix(iNeuron,:);
    %av_neuron = av{iNeuron};
%     y = zeros(size(x));
%     for iSample = 1:numTimeSamples
%         iA = find(av_neuron >= traceMatrix(iNeuron,iSample), 1, 'first');
%         y(iSample) = iA;
%     end
    my = mean(y,'all');
    y = y - my;
    ry = max(y) - min(y);
    y = y ./ ry*2;
    
    plot(x, y + iNeuron, 'linewidth', 1);
    hold on
end
axis tight

end % function
