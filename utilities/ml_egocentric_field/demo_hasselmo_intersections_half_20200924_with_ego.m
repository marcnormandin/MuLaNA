close all
clear all
clc

% mouseImage = imresize(imread('light-grey-mouse-md.png'), [10,10]);
% figure
% imshow(mouseImage)
% 
% figure
% heatmap(mouseImage)
% 
% mouseImage(mouseImage > 220) = nan;

%%
minDistance = 10;

%a = 100;
%poly = [0 0; a, 0; a, a; 0, a];
a = [0, 20];
b = [0, 0];
c = [30, 0];
d = [30, 20];
refCanPts = [a(1), b(1), c(1), d(1); a(2), b(2), c(2), d(2)];
poly = refCanPts';

% figure
% 
% plot(poly(:,1), poly(:,2), 'b-*', 'linewidth', 10)
% hold on
% plot([poly(1,1), poly(end,1)], [poly(1,2), poly(end,2)], 'b-*', 'linewidth', 10)
% grid on
% hold off

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
occupancy = zeros(22,22);

tstart = tic;
 numSimulations = 1000;
 mhdr = 0;
 Mv = randi([1,a(2)-1], 1,2);
     h = figure('position', get(0, 'screensize'));

         angles = 0:4:180;
    intersections = zeros(length(angles),2); % Every angle will have an intersection since the shape is convex
    intersectionsOp = zeros(length(angles),2); % Every angle will have an intersection since the shape is convex
    intersectionsDistance = zeros(length(angles),1);
    intersectionsOpDistance = zeros(length(angles),1);
    
% Mvprev = [];
mhdrprev = 0;
for iSim = 1:numSimulations
    clf(h, 'reset');

    % Mouse heading direction in degrees
    mhdr = mhdrprev + randi([-45,45],1,1);
    mhdrprev = mhdr;
    
    speed = 2;
    Mv = Mv + [cosd(mhdr)*speed, sind(mhdr)*speed];
    
    %Mv = [Mi, Mj];
    %Mv = randi([1,a(2)-1], 1,2);
    %Mv = Mv + randi([-2,2], 1, 2); % previous working
    
%     if isempty(Mvprev)
%         Mvprev = Mv;
%     end
    
    if Mv(1) < 2
        Mv(1) = 4;
    elseif Mv(1) > 29
        Mv(1) = 29;
    end
    
    if Mv(2) < 2
        Mv(2) = 4;
    elseif Mv(2) > 19
        Mv(2) = 19;
    end
    
    %mhdr = 0; % Mouse heading direction
    %mhdr = mhdr + randi([-20,20], 1, 1); % prev working
    
    % Mouse heading direction
    %mhdr = atan2d( Mv(2) - Mvprev(2), Mv(1) - Mvprev(1) );
    
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
    %Plot the heading direction
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
    for i = 1:size(intersections,1)
       currentIntersection = intersections(i,:);
       dist = sqrt((Mv(1) - intersections(i,1)).^2 + (Mv(2) - intersections(i,2)).^2);
       distOp = sqrt((Mv(1) - intersectionsOp(i,1)).^2 + (Mv(2) - intersectionsOp(i,2)).^2);
       
       Rv = [cosd(angles(i)), sind(angles(i))];
      
       offset = 90;
       if dist < minDistance
           dy = intersections(i,2) - Mv(2);
           dx = intersections(i,1) - Mv(1);
           alloAngle = atan2d( dy, dx );
           headingAngle = mhdr;
           egoAngle = alloAngle - headingAngle + offset;
           
           ego = dist * [cosd(egoAngle), sind(egoAngle)];
           
           
           ix = round(ego(1));
           iy = round(ego(2));
           ix = ix + minDistance + 1;
           iy = iy + minDistance + 1;
           plot(ix, iy, 'ko', 'markerfacecolor', 'k')
           occupancy(iy, ix) = occupancy(iy, ix) + 1;
       end
       
       if distOp < minDistance
           dy = intersections(i,2) - Mv(2);
           dx = intersections(i,1) - Mv(1);
           alloAngle = atan2d( dy, dx );
           headingAngle = mhdr;
           egoAngle = alloAngle - headingAngle + offset + 180;
           
           ego = distOp * [cosd(egoAngle), sind(egoAngle)];
           
           ix = round(ego(1));
           iy = round(ego(2));
           ix = ix + minDistance + 1;
           iy = iy + minDistance + 1;
           plot(ix, iy, 'ko', 'markerfacecolor', 'k')
           occupancy(iy, ix) = occupancy(iy, ix) + 1;
       end
       
    end
    
%     MI = zeros(10,10,3);
%     MI(:,:,1) = mouseImage;
%     MI(:,:,2) = mouseImage;
%     MI(:,:,3) = mouseImage;
    
    %image([5 5], [15 15], MI);
    %imshow(mouseImage)
    axis equal off
    hold off
    
    drawnow
    %pause(1)
    
%     Mvprev = Mv;
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
