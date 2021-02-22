close all
clear all
clc

tfolder = pwd;

d1 = load( fullfile(tfolder, 'behavcam_roi.mat') );

% The coordinates of the reference points in the video frame (pixels)
refVidPts = [d1.behavcam_roi.inside.i'; d1.behavcam_roi.inside.j'];

% The coordinates of the reference points in the canonical frame
% For the rectangle/square, the feature is at the top/north
%L = 1;
a = [0, 20];
b = [0, 0];
c = [30, 0];
d = [30, 20];

% a = [0, 1];
% b = [0, 0];
% c = [1, 0];
% d = [1, 1];

refCanPts = [a(1), b(1), c(1), d(1); a(2), b(2), c(2), d(2)];

% Get the transformation matrix
v = homography_solve(refVidPts, refCanPts);

% The behaviour data
d2 = load( fullfile(tfolder, 'behaviour_scope_videocoords.mat') );
behav = d2.behaviour_scope_videocoords;

% Transform the position to canonical coordinates
x = homography_transform(behav.pos', v);
posCan = x';

% Transform the two led positions canonical coordinates
% and then compute the angle
x1 = homography_transform(behav.ledPos1', v);
x1 = x1';
x2 = homography_transform(behav.ledPos2', v);
x2 = x2';
aa = atan2(x2(:,1)- x1(:,1), x2(:,2)- x1(:,2));
bb = find(aa < 0);
aa(bb) = aa(bb) + 2*pi;
lookDegCan = rad2deg(aa);

% We need to make sure that the position is inside the arena polygon
% or else the procedure to find the distances will fail.
insideArena = inpolygon(posCan(:,2), posCan(:,1), refCanPts(2,:), refCanPts(1,:));
posCan(~insideArena) = [];
lookDegCan(~insideArena) = [];

% The occupancy map. For every mouse position it will have a heading, and
% we will need to compute the distances for each angle we want.
mouseEgocentricAngles = 0:0.5:180; % only use half
allDistances = nan(length(lookDegCan), 2*length(mouseEgocentricAngles)-1);
poly = refCanPts';
for iLook = 1:length(lookDegCan)
    mouseHeadingDeg = lookDegCan(iLook);
    mousePosition = posCan(iLook,:);
    % allAngles will always be the same
    [allAngles, allDistances(iLook,:)] = ml_cai_egocentric_compute_distances(mousePosition, mouseHeadingDeg, mouseEgocentricAngles, poly);
end


numNeurons = h5readatt(fullfile(tfolder, 'neuron.hdf5'), '/', 'num_neurons');
k = 1;
for nid = 1:numNeurons
    spikes = h5read(fullfile(tfolder, 'neuron.hdf5'), sprintf('/neuron_%d/spikes', nid));
    % Filter out those that happen outside the arena
    spikes(~insideArena) = [];
    
    activeIndices = find(spikes ~= 0);

    activeDistances = allDistances(activeIndices,:);
    
    activePosCan = posCan(activeIndices,:);
    activeVal = spikes(activeIndices);
    activeLookDegCan = lookDegCan(activeIndices);

    % threshold
    threshold = quantile(activeVal, 0.5);
    badIndices = find(activeVal < threshold);
    activeVal(badIndices) = [];
    activeLookDegCan(badIndices) = [];
    activePosCan(badIndices,:) = [];

    activeDistances(badIndices,:) = [];
    
    edges = 0:6:360;
    centers = 3:6:360;
    huelinear = linspace(0, 1, length(centers));
    satlinear = 0.8*ones(1, length(centers));
    vallinear = ones(1, length(centers));

    [~, ~, bi] = histcounts(activeLookDegCan, edges);
    activeLookColor = hsv2rgb([huelinear(bi)' satlinear(bi)' vallinear(bi)']);

    if k == 1
        h = figure('Name', sprintf('Hasselmo %d', nid), 'Position', get(0,'Screensize'));
    end
    p = 4; q = 6;
    maxK = p*q;
    subplot(p,q,k);

    plot(posCan(:,2), posCan(:,1), 'k-')
    %set(gca, 'ydir', 'reverse')
    %axis equal tight square
    hold on
    %subplot(1,2,2)
    scatter(activePosCan(:,2), activePosCan(:,1), 'filled', 'markerfacealpha', 0.9, 'CData', activeLookColor)
    set(gca, 'ydir', 'reverse')
    axis equal tight
    
    subplot(p,q,k+1)
    NBINS = 100;
    theta = allAngles;

    % Form the occupancy map
    occupancyRho = allDistances;
    occupancyTHETA = repmat(theta, size(occupancyRho,1), 1);
    occupancyX = occupancyRho .* cosd(occupancyTHETA);
    occupancyY = occupancyRho .* sind(occupancyTHETA);
    [OM, occupancyXEDGES, occupancyYEDGES] = histcounts2(occupancyX, occupancyY, NBINS);
    OMF = imgaussfilt(OM,2);

    % Form the activity map
    activeRho = activeDistances;
    activeTHETA = repmat(theta, size(activeRho,1), 1);
    activeX = activeRho .* cosd(activeTHETA);
    activeY = activeRho .* sind(activeTHETA);
    [AM, XEDGES, YEDGES] = histcounts2(activeX, activeY, occupancyXEDGES, occupancyYEDGES);
    AMF = imgaussfilt(AM,2);

    imagesc(imgaussfilt(AM ./ OM, 2))
    colormap jet
    colorbar
    axis equal tight
    
    
   
    k = k + 2;
    if k > maxK
        k = 1;
    end
    
end
