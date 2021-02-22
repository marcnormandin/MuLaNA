close all
clear all
clc

minDistance = 10;

%a = 100;
%poly = [0 0; a, 0; a, a; 0, a];
a = [0, 20];
b = [0, 0];
c = [30, 0];
d = [30, 20];
refCanPts = [a(1), b(1), c(1), d(1); a(2), b(2), c(2), d(2)];
poly = refCanPts';

figure

plot(poly(:,1), poly(:,2), 'b-*', 'linewidth', 10)
hold on
plot([poly(1,1), poly(end,1)], [poly(1,2), poly(end,2)], 'b-*', 'linewidth', 10)
grid on
hold off

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
[Mi, Mj] = getpts();
%%
tstart = tic;
 numSimulations = 1000;
 mhdr = 0;
 Mv = randi([1,a(2)-1], 1,2);
for iSim = 1:numSimulations
    angles = 0:3:180;
    intersections = zeros(length(angles),2); % Every angle will have an intersection since the shape is convex
    intersectionsOp = zeros(length(angles),2); % Every angle will have an intersection since the shape is convex
    intersectionsDistance = zeros(length(angles),1);
    intersectionsOpDistance = zeros(length(angles),1);
    
    %Mv = [Mi, Mj];
    %Mv = randi([1,a(2)-1], 1,2);
    Mv = Mv + randi([-2,2], 1, 2);
    
    if Mv(1) < 2
        Mv(1) = 2;
    elseif Mv(1) > 29
        Mv(1) = 29;
    end
    
    if Mv(2) < 2
        Mv(2) = 2;
    elseif Mv(2) > 19
        Mv(2) = 19;
    end
    
    %mhdr = 0; % Mouse heading direction
    mhdr = mhdr + randi([-20,20], 1, 1);
    
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
                
        % Find the smallest negative one
        kk = find(sortedR < 0, 1, 'last');
        bestRop = R(Ri(kk));
        
        
        intersectionsOp(iAngle,:) = Mv + bestRop*Rv;
        
        intersectionsDistance(iAngle) = bestR;
        if intersectionsDistance(iAngle) < minDistance
            intersectionsDistance(iAngle) = nan;
        end
        
        intersectionsOpDistance(iAngle) = bestRop;
        if intersectionsOpDistance(iAngle) < minDistance
            intersectionsOpDistance(iAngle) = nan;
        end
    end

    figure(1)

    plot(poly(:,1), poly(:,2), 'b-*', 'linewidth', 10)
    hold on
    plot([poly(1,1), poly(end,1)], [poly(1,2), poly(end,2)], 'b-*', 'linewidth', 10)
    grid on

    for i = 1:size(intersections,1)
       currentIntersection = intersections(i,:);
%        if ~isnan(intersectionsDistance(i))
%            plot([Mv(1), intersections(i,1)], [Mv(2), intersections(i,2)], 'k-*')
%        end
%        
%        if ~isnan(intersectionsOpDistance(i))
%            plot([Mv(1), intersectionsOp(i,1)], [Mv(2), intersectionsOp(i,2)], 'r-*')
%        end
       dist = sqrt((Mv(1) - intersections(i,1)).^2 + (Mv(2) - intersections(i,2)).^2);
       distOp = sqrt((Mv(1) - intersectionsOp(i,1)).^2 + (Mv(2) - intersectionsOp(i,2)).^2);
       if dist < minDistance
           plot([Mv(1), intersections(i,1)], [Mv(2), intersections(i,2)], 'k-*')
       end
       
       if distOp < minDistance
           plot([Mv(1), intersectionsOp(i,1)], [Mv(2), intersectionsOp(i,2)], 'k-*')
       end
       
    end
    %Plot the heading direction
    Rv = [cosd(mhdr), sind(mhdr)];
    b = 4;
    plot([Mv(1), Mv(1) + b*Rv(1)], [Mv(2), Mv(2) + b*Rv(2)], 'm-', 'linewidth', 5)
    
    circle(Mv(1), Mv(2), minDistance);
    axis([-10, 40, -10, 40])
    daspect([1 1 1])
    %axis equal
    hold off
    drawnow
    pause(1)
end
%axis square
% telapsed = toc(tstart);
% fprintf('Computation time for %d simulations: %f secs\n', numSimulations, telapsed)

function h = circle(x,y,r)
    th = 0:pi/50:2*pi;
    xunit = r * cos(th) + x;
    yunit = r * sin(th) + y;
    h = plot(xunit, yunit, 'k-');
end % function
