function [h] = men_behaviour_roi_plot( roi, useGrayscale )

h = figure;

F = roi.refFrame;
if useGrayscale
    F = imadjust(rgb2gray(F));
end
imshow(F)

hold on

% Plot the inside boundary
plot([roi.inside.j(:); roi.inside.j(1)], [roi.inside.i(:); roi.inside.i(1)], 'ro-')

% Plot the outside boundary
plot([roi.outside.j(:); roi.outside.j(1)], [roi.outside.i(:); roi.outside.i(1)], 'yx-')

hold off

% Plot the other ROI if they exist
if isfield(roi, 'other')
    hold on
    plot(roi.other.j, roi.other.i, 'bo', 'markerfacecolor', 'b')
    hold off
end

% Find the maximum confined to the floor ROI
% iq = zeros(1, numel(roi.refFrame));
% jq = zeros(1, numel(roi.refFrame));
% m = 0;
% for j = 1:size(roi.refFrame,2)
%     for i = 1:size(roi.refFrame,1)
%         m = m + 1;
%         iq(m) = i;
%         jq(m) = j;
%     end
% end
% 
% inArena = inpolygon(iq,jq, roi.outside.i, roi.outside.j);
% inFloor = inpolygon(iq,jq, roi.inside.i, roi.inside.j);
% inWall = inArena & ~inFloor;
% inOutside = ~inArena;
% 
% hold on
% inWallI = iq(inWall);
% inWallJ = jq(inWall);
% inFloorI = iq(inFloor);
% inFloorJ = jq(inFloor);
% inOutsideI = iq(inOutside);
% inOutsideJ = jq(inOutside);
% 
% plot(inWallJ, inWallI, 'y.')
% plot(inFloorJ, inFloorI, 'r.')
% plot(inOutsideJ, inOutsideI, 'k.')

% hold off

end % function
