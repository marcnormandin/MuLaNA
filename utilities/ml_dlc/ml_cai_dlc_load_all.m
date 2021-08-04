function [trackedPoints] = ml_cai_dlc_load_all(trialDLCFolder)
% This code reads in the multiple h5 files produced by DeepLabCut

numBehavCamFiles = length(dir(fullfile(trialDLCFolder, 'behavCam*_DLC.h5')));
if numBehavCamFiles == 0
    error('Unable to read any behavCam#DLC...h5 files from %s', trialDLCFolder);
end

numTrackedPoints = [];
trackedPoints = [];
for iBehavCamNum = 1:numBehavCamFiles
    % We don't know what the specific name of the file will be, but know
    % what it will start with
    fnPrefix = sprintf('behavCam%d_DLC.h5', iBehavCamNum);
    fnn = dir(fullfile(trialDLCFolder, fnPrefix));
    
    if isempty(fnn)
        error('Error! Unable to find %s for reading!', fnPrefix);
    end
    
    fn = fullfile(fnn.folder, fnn.name);
    %fprintf('Reading %s to get the tracking data from DeepLabCut\n', fn);
    
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
