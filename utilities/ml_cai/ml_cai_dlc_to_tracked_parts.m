function [trackedParts] = ml_cai_dlc_to_tracked_parts(trialDLCFolder)
% This code reads in the multiple h5 files produced by DeepLabCut
% and then converts the data so that it can be saved as a
% a single behaviour.h5 file

trackedParts = struct('name', [], 'x', [], 'y', [], 'p', []);

% These are the numbers for the CA1 animals
% 1 - earleft
% 2 - earright
% 3 - miniscope
% 4 - hip
% 5 - tailbase
trackedParts(1).name = 'ear_left';
trackedParts(2).name = 'ear_right';
trackedParts(3).name = 'miniscope_led';
trackedParts(4).name = 'hip';
trackedParts(5).name = 'tail_base';

numTrackedParts = length(trackedParts);


numBehavCamFiles = length(dir(fullfile(trialDLCFolder, 'behavCam*_DLC.h5')));
if numBehavCamFiles == 0
    error('Unable to read any behavCam#DLC...h5 files from %s', trialDLCFolder);
end

for iBehavCamNum = 1:numBehavCamFiles
    % We don't know what the specific name of the file will be, but know
    % what it will start with
    fnPrefix = sprintf('behavCam%d_DLC.h5', iBehavCamNum);
    fnn = dir(fullfile(trialDLCFolder, fnPrefix));
    
    if isempty(fnn)
        error('Error! Unable to find %s for reading!', fnPrefix);
    end
    
    fn = fullfile(fnn.folder, fnn.name);
    fprintf('Reading %s to get the tracking data from DeepLabCut\n', fn);
    
    %iBodyPart = 3; % miniscope
    data = h5read(fn, '/df_with_missing/table');

    for iTrackedPart = 1:numTrackedParts
        trackedParts(iTrackedPart).x = [trackedParts(iTrackedPart).x data.values_block_0((iTrackedPart-1)*3+1, :)];
        trackedParts(iTrackedPart).y = [trackedParts(iTrackedPart).y data.values_block_0((iTrackedPart-1)*3+2, :)];
        trackedParts(iTrackedPart).p = [trackedParts(iTrackedPart).p data.values_block_0((iTrackedPart-1)*3+3, :)];
    end
end



end % function

