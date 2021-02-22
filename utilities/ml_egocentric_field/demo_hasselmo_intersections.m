close all
clear all
clc

a = 100;
poly = [0 0; a, 0; a, a; 0, a];

%figure

%plot(poly(:,1), poly(:,2), 'b-*', 'linewidth', 10)
%hold on
%plot([poly(1,1), poly(end,1)], [poly(1,2), poly(end,2)], 'b-*', 'linewidth', 10)
%grid on

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
%%
numSegments = size(segment_unit_vector,1);
%%
% M vector represents the mouse location
%[Mi, Mj] = getpts();
%%
tstart = tic;
numSimulations = 10000;
for iSim = 1:numSimulations
    angles = 0:3:360;
    intersections = zeros(length(angles),2); % Every angle will have an intersection since the shape is convex
    %Mv = [Mi, Mj];
    Mv = randi([1,a-1], 1,2);
    mhdr = -15; % Mouse heading direction

    for iAngle = 1:length(angles)
        Rv = [cosd(angles(iAngle)-mhdr), sind(angles(iAngle)-mhdr)];
        R = ones(numSegments,1)*1e15;
        for iSegment = 1:numSegments

            lv = segment_unit_vector(iSegment,:);

            alpha = lv*Rv';
            if alpha == 1
                % Skip since the line segment is parallel
                continue
            end
            av = segment_origin_vector(iSegment,:);

            % If alpha^2 == 1, we have a problem!
            R(iSegment) = (Mv - av)*(Rv - alpha*lv)' / (alpha^2 - 1);
        end

        % Sort the distance and find the smallest one that is postive-valued
        [sortedR, Ri] = sort(R);
        k = find(sortedR >= 0, 1, 'first');
        bestR = R(Ri(k));
        intersections(iAngle,:) = Mv + bestR*Rv;
    end

    %for i = 1:size(intersections,1)
    %    plot([Mv(1), intersections(i,1)], [Mv(2), intersections(i,2)], 'k-*')
    %end
end
telapsed = toc(tstart);
fprintf('Computation time for %d simulations: %f secs\n', numSimulations, telapsed)

%axis equal