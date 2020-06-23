function [allAngles, allDistances] = ml_cai_egocentric_compute_distances(mousePosition, mouseHeadingDeg, mouseEgocentricAngles, poly)
Mv = mousePosition; %[mousePosition(2) mousePosition(1)];
mhdr = mouseHeadingDeg;
angles = mouseEgocentricAngles; % egocentric angle 0 corresponds to mouse heading direction

numPoly = length(poly);
polyh = poly;
% This is just to help compute the line segment angles
polyh(numPoly+1,:) = poly(1,:);
segment_unit_vector = zeros(numPoly,2);
segment_origin_vector = zeros(numPoly,2);
for i = 1:numPoly
    segment_origin_vector(i,:) = polyh(i,:);
    l = polyh(i+1,:) - polyh(i,:);
    segment_unit_vector(i,:) = l ./ sqrt(l(1)^2 + l(2)^2);
end
numSegments = size(segment_unit_vector,1);

%intersections = zeros(length(angles),2); % Every angle will have an intersection since the shape is convex
%intersectionsOp = zeros(length(angles),2); % Every angle will have an intersection since the shape is convex

bestR = zeros(1, length(angles));
bestRop = zeros(1, length(angles));

for iAngle = 1:length(angles)
    Rv = [cosd(angles(iAngle)-mhdr), sind(angles(iAngle)-mhdr)];
    R = ones(1, numSegments)*1e15;
    for iSegment = 1:numSegments

        lv = segment_unit_vector(iSegment,:);

        alpha = lv*Rv';
%         if alpha >= 0.9999
%             % Skip since the line segment is parallel
%             continue
%         end
        av = segment_origin_vector(iSegment,:);

        % If alpha^2 == 1, we have a problem!
        if alpha^2 ~= 1% 0.9999
         
            R(iSegment) = (Mv - av)*(Rv - alpha*lv)' / (alpha^2 - 1);
            %if R(iSegment) > 100
            %    fprintf('> 100 -> alpha^2 = %f at iangle (%d) iseg (%d)\n', alpha^2, iAngle, iSegment)
            %end
        end
    end

    % Sort the distance and find the smallest one that is postive-valued
    [sortedR, Ri] = sort(R);
    k = find(sortedR >= 0, 1, 'first');
    bestR(iAngle) = R(Ri(k));
    %intersections(iAngle,:) = Mv + bestR*Rv;

    % Find the smallest negative one
    kk = find(sortedR < 0, 1, 'last');
    bestRop(iAngle) = -R(Ri(kk));
    %intersectionsOp(iAngle,:) = Mv + bestRop*Rv;
end

allAngles = [angles, (angles+180)];
allDistances = [bestR, bestRop];

%size(allAngles)
%size(allDistances)

% Make sure that we don't have duplicated angles
[uniqueA, i, j] = unique(allAngles, 'first');
indexToDupes = find(not(ismember(1:numel(allAngles),i)));
allAngles(indexToDupes) = [];
allDistances(indexToDupes) = [];

end % function

