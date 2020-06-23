function [quality] = ml_cai_quality_led_position_difference(x, a)

% Compute the difference in the position between frames
% This assumes that the frames are sequential and about the same frame rate
dv = diff(x); % dv has one less element than ledPosPixel
dvMedian = median(dv);
dvMAD = median( abs(dv - dvMedian) );
dvMADThreshold = a * dvMAD;

quality = zeros(size(x));
badIndices = find(abs( dv - dvMedian ) > dvMADThreshold) + 1; % shift by one to save that the difference of the second element is too great
quality(badIndices) = 1;

end % function
