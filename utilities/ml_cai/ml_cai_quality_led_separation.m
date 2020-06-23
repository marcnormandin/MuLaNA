function [quality] = ml_cai_quality_led_separation(x1, x2, minSep, maxSep)
% x1 should be (N,2) where x(1,:) = i, j
N = size(x1, 1);
if size(x1) ~= size(x2)
    error('The sizes of x1 and x2 must be the same.')
end

% Calculate the distance between the two leds
sep = sqrt( (x1(:,1) - x2(:,1)).^2 + (x1(:,2) - x2(:,2)).^2 );

tooClose = find( sep < minSep );
tooFar = find( sep > maxSep );
badIndices = union( tooClose, tooFar );

quality = zeros(N,1);
quality(badIndices) = 1;

end % function

