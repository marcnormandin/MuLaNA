close all
clear all
clc

minDistance = 10;
xedges = linspace(-minDistance, minDistance, 100);
yedges = linspace(-minDistance, minDistance, 100);

DO_ANIMATION = true;
HEADING_OFFSET_DEG = 90;

% Arena
a = [0, 30];
b = [0, 0];
c = [20, 0];
d = [20, 30];
refCanPts = [a(1), b(1), c(1), d(1); a(2), b(2), c(2), d(2)];
poly = refCanPts';

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


%occupancy = zeros(22,22);
occupancy = zeros(length(yedges)-1,length(xedges)-1);


tstart = tic;
 numSimulations = 1000;
 mhdr = 0;
 Mv = randi([1,a(2)-1], 1,2);
 
 if DO_ANIMATION
     h = figure('position', get(0, 'screensize'));
 end

         angles = 0:1:180;
    intersections = zeros(length(angles),2); % Every angle will have an intersection since the shape is convex
    intersectionsOp = zeros(length(angles),2); % Every angle will have an intersection since the shape is convex
    intersectionsDistance = zeros(length(angles),1);
    intersectionsOpDistance = zeros(length(angles),1);
    
% Mvprev = [];
mhdrprev = 0;
for iSim = 1:numSimulations
    if DO_ANIMATION
        clf(h, 'reset');
    end

    % Mouse heading direction in degrees
    %mhdr = mhdrprev + randi([-45,45],1,1);
    %mhdrprev = mhdr;
    
    %speed = 2;
%     Mv = Mv + [cosd(mhdr)*speed, sind(mhdr)*speed];

    mhdr = randi([-180, 180], 1, 1);
    Mv(1) = randi([1, 19], 1, 1);
    Mv(2) = randi([1, 29], 1, 1);
      
    if Mv(1) <= 0
        Mv(1) = 0.1;
    elseif Mv(1) >= 30 
        Mv(1) = 29.9;
    end
    
    if Mv(2) <= 0
        Mv(2) = 0.1;
    elseif Mv(2) >= 20
        Mv(2) = 19.9;
    end
    
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


    if DO_ANIMATION
        subplot(1,2,1)
        plot(poly(:,1), poly(:,2), 'b-o', 'linewidth', 10)
        hold on
        plot([poly(1,1), poly(end,1)], [poly(1,2), poly(end,2)], 'b-o', 'linewidth', 10)
        grid on

        for i = 1:size(intersections,1)
           currentIntersection = intersections(i,:);
           dist = sqrt((Mv(1) - intersections(i,1)).^2 + (Mv(2) - intersections(i,2)).^2);
           distOp = sqrt((Mv(1) - intersectionsOp(i,1)).^2 + (Mv(2) - intersectionsOp(i,2)).^2);
           if dist < minDistance
               plot([Mv(1), intersections(i,1)], [Mv(2), intersections(i,2)], 'k-o')
           end

           if distOp < minDistance
               plot([Mv(1), intersectionsOp(i,1)], [Mv(2), intersectionsOp(i,2)], 'k-o')
           end

        end
    end
    
    
    %Plot the heading direction
    if DO_ANIMATION
        Rv = [cosd(mhdr), sind(mhdr)];
        b = 4;
        plot([Mv(1), Mv(1) + b*Rv(1)], [Mv(2), Mv(2) + b*Rv(2)], 'm-', 'linewidth', 5)

        circle(Mv(1), Mv(2), minDistance);
        axis([-10, 40, -10, 40])
        daspect([1 1 1])
        axis off
        %axis equal
        hold off


        subplot(1,2,2)
        hold on
        occupancyShow = imgaussfilt(occupancy, 2);
        occupancyShow(occupancy == 0) = nan;
        %imagesc(occupancy)
        pcolor(occupancyShow)
        shading flat
        colormap jet
    end
    
    
    
    
    for i = 1:size(intersections,1)
       currentIntersection = intersections(i,:);
       dist = sqrt((Mv(1) - intersections(i,1)).^2 + (Mv(2) - intersections(i,2)).^2);
       distOp = sqrt((Mv(1) - intersectionsOp(i,1)).^2 + (Mv(2) - intersectionsOp(i,2)).^2);
       
       Rv = [cosd(angles(i)), sind(angles(i))];
      
       if dist < minDistance
           dy = intersections(i,2) - Mv(2);
           dx = intersections(i,1) - Mv(1);
           alloAngle = atan2d( dy, dx );
           headingAngle = mhdr;
           egoAngle = alloAngle - headingAngle + HEADING_OFFSET_DEG;
           
           ego = dist * [cosd(egoAngle), sind(egoAngle)];
           

           
           ix = discretize(ego(1), xedges);
           iy = discretize(ego(2), yedges);
%            ix = round(ego(1));
%            iy = round(ego(2));
%            ix = ix + minDistance + 1;
%            iy = iy + minDistance + 1;
           
           if DO_ANIMATION
            plot(ix, iy, 'ko', 'markerfacecolor', 'k')
           end
           
           occupancy(iy, ix) = occupancy(iy, ix) + 1;
       end
       
       if distOp < minDistance
           dy = intersections(i,2) - Mv(2);
           dx = intersections(i,1) - Mv(1);
           alloAngle = atan2d( dy, dx );
           headingAngle = mhdr;
           egoAngle = alloAngle - headingAngle + HEADING_OFFSET_DEG + 180;
           
           ego = distOp * [cosd(egoAngle), sind(egoAngle)];
           

           
           ix = discretize(ego(1), xedges);
           iy = discretize(ego(2), yedges);
           
%            ix = round(ego(1));
%            iy = round(ego(2));
%            ix = ix + minDistance + 1;
%            iy = iy + minDistance + 1;
           
           if DO_ANIMATION
            plot(ix, iy, 'ko', 'markerfacecolor', 'k')
           end
           

           occupancy(iy, ix) = occupancy(iy, ix) + 1;
       end
       
    end

    if DO_ANIMATION
        axis equal off
        hold off
        title(sprintf('%d\n', iSim))

        drawnow
    end
end

function h = circle(x,y,r)
    th = 0:pi/50:2*pi;
    xunit = r * cos(th) + x;
    yunit = r * sin(th) + y;
    h = plot(xunit, yunit, 'k-');
end % function
