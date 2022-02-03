function [trackedPoints] = ml_cai_dlc_load_all(containerFolder, filenamePrefix)
% This code reads in the multiple h5 files produced by DeepLabCut

% Get a list of matching filenames
h5Files = ml_cai_dlc_get_h5_filenames(containerFolder, filenamePrefix);

numH5Files = length(h5Files);
if numH5Files == 0
    error('Unable to read any behavCam#DLC...h5 files from %s', containerFolder);
end

numTrackedPoints = [];
trackedPoints = [];
for iFileNum = 1:numH5Files
    fn = h5Files(iFileNum).filename;
    
    data = h5read(fn, '/df_with_missing/table');
    
    numTrackedPointsCurrent = size(data.values_block_0,1)/3; % each point has x, y, p
    numFrames = size(data.values_block_0,2);
    
    % If this is the first file we have loaded
    if isempty(numTrackedPoints)
        numTrackedPoints = numTrackedPointsCurrent;
    end
    
    if numTrackedPoints ~= numTrackedPointsCurrent
        error('The number of points being tracked (%d) does not match the number of points being tracked (%d) in the current file (%s).', numTrackedPoints, numTrackedPointsCurrent, fn);
    end
    
    trackedPointsCurrent = zeros(numTrackedPoints, 3, numFrames);
    
    for iTrackedPoint = 1:numTrackedPoints
        xnew = data.values_block_0((iTrackedPoint-1)*3+1, :); % 1x1000
        ynew = data.values_block_0((iTrackedPoint-1)*3+2, :); % 1x1000
        pnew = data.values_block_0((iTrackedPoint-1)*3+3, :); % 1x1000
                
        trackedPointsCurrent(iTrackedPoint, 1, :) = xnew; 
        trackedPointsCurrent(iTrackedPoint, 2, :) = ynew;
        trackedPointsCurrent(iTrackedPoint, 3, :) = pnew;
    end % iTrackedPoint
    
    if isempty(trackedPoints)
        trackedPoints = trackedPointsCurrent;
    else
        trackedPoints = cat(3, trackedPoints, trackedPointsCurrent);
    end
end

end % function
