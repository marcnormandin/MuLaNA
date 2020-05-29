function [track] = ml_cai_dlc_to_mlbehaviourtrack_with_heading(trialDLCFolder, timestamp_ms)
% This code reads in the multiple h5 files produced by DeepLabCut
% and then converts the data so that it can be saved as a
% MLBehaviourTrack hdf5 file used by the pipeline.

%trialDLCFolder = pwd;
%trialAnalysisFolder = pwd;

% These are the numbers for the CA1 animals
% 1 - nose
% 2 - earleft
% 3 - earright
% 4 - miniscope
% 5 - hip
% 6 - tailbase
% 7 - tailtip
% Only the miniscope seems to be stable without furthering training
% on particular sessions.

pos = [];
numBehavCamFiles = length(dir(fullfile(trialDLCFolder, 'behavCam*.h5')));
if numBehavCamFiles == 0
    error('Unable to read any behavCam#DLC...h5 files from %s', trialDLCFolder);
end

lx = [];
ly = [];
lp = [];

rx = [];
ry = [];
rp = [];
for iBehavCamNum = 1:numBehavCamFiles
    % We don't know what the specific name of the file will be, but know
    % what it will start with
    fnPrefix = sprintf('behavCam%d.h5', iBehavCamNum);
    fnn = dir(fullfile(trialDLCFolder, fnPrefix));
    
    if isempty(fnn)
        error('Error! Unable to find %s for reading!', fnPrefix);
    end
    
    fn = fullfile(fnn.folder, fnn.name);
    fprintf('Reading %s to get the tracking data from DeepLabCut\n', fn);
    
    iBodyPartLeftEar = 1; % starting the count at 1 (4 == miniscope)
    iBodyPartRightEar = 2;
    
    data = h5read(fn, '/df_with_missing/table');
    lx = [lx data.values_block_0((iBodyPartLeftEar-1)*3+1, :)];
    ly = [ly data.values_block_0((iBodyPartLeftEar-1)*3+2, :)];
    lp = [lp data.values_block_0((iBodyPartLeftEar-1)*3+3, :)];
    
    rx = [rx data.values_block_0((iBodyPartRightEar-1)*3+1, :)];
    ry = [ry data.values_block_0((iBodyPartRightEar-1)*3+2, :)];    
    rp = [rp data.values_block_0((iBodyPartRightEar-1)*3+3, :)];
end

fprintf('Converting the data from DeepLabCut h5 files to the MLBehaviourTrack object for saving ... ');
ledColours = {'red', 'green'};
ledPos{1} = zeros(length(lx),3);
ledPos{1}(:,1) = lx;
ledPos{1}(:,2) = ly;
ledPos{1}(:,3) = lp;
ledPos{2} = zeros(length(rx),3);
ledPos{2}(:,1) = rx;
ledPos{2}(:,2) = ry;
ledPos{2}(:,3) = rp;

%timestamp_ms = zeros(length(x),1);
track = MLBehaviourTrack(ledColours, ledPos, timestamp_ms);
fprintf('done!\n');

end % function

