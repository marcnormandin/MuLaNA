function [entropy] = ml_alg_entropy_image(I)
    % Ia and Ib must be discrete valued

ind = double(I(:))+1;
hist = accumarray(ind, 1);
prob = hist ./ numel(ind);
indNoZero = hist ~= 0;
prob1DNoZero = prob(indNoZero);
entropy = -sum( prob1DNoZero .* log2( prob1DNoZero ) );
end