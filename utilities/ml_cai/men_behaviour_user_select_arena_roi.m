function [roi] = men_behaviour_user_select_arena_roi( referenceFrame, includeOtherROI, useGrayscale)

F = referenceFrame;
if useGrayscale
    F = imadjust(rgb2gray(referenceFrame));
end
% Modified to make finding the edges easier in the dark arena
% HSV = rgb2hsv(referenceFrame);
% BW = edge(HSV(:,:,3),'canny');
% F = referenceFrame;
% for j = 1:size(BW,2)
%     for i = 1:size(BW,1)
%         if BW(i,j) == 1
%             F(i,j,1) = 255;
%             F(i,j,2) = 255;
%             F(i,j,3) = 255;
%         end
%     end
% end

h = figure;
hold on
fprintf('ROI reference points will be asked for. Hit enter after points are selected.\n');
imshow(F)
fprintf('Select inside vertices:\n');
[jIn,iIn] = getpts(h);
fprintf('Select outside vertices:\n');
[jOut,iOut] = getpts(h);

if includeOtherROI
    fprintf('Select other centers of ROI:\n');
    [jOther, iOther] = getpts(h);
end

close(h)

roi.refFrame = referenceFrame;
roi.inside.i = iIn;
roi.inside.j = jIn;
roi.outside.i = iOut;
roi.outside.j = jOut;

if includeOtherROI
    roi.other.i = iOther;
    roi.other.j = jOther;
end

fprintf('Done finding reference points.\n');

end % function
