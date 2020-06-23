function [frame] = plotSFPs(obj)
% Plot the combined spatial footsprints of this trials neurons

[frameWidth, frameHeight] = obj.getScopeVideoDimensions();
numNeurons = obj.getNumNeurons();

% the frame we will make
frame = zeros(frameHeight, frameWidth);

for iNeuron = 1:numNeurons
    neuron = obj.getNeuronById(iNeuron);
    sfp = neuron.getSpatialFootprint();
    frame = frame + sfp;
end

imagesc(frame)
colormap jet
axis equal tight

end % function
