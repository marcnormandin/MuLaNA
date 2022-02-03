function [dp, dpAvg] = ml_alg_popvectors_compute_dotproducts(maps1, maps2)
    % Marc Normandin.
    % maps1 and maps2 are (map_height, map_width, num_cells) 3D arrays.

    if ~all(size(maps1) == size(maps2), 'all')
        error('maps1 and maps2 must be the same sized stacks of maps.\n');
    end

    % Each columns is a cells data, so each row is a population vector
    maps1 = reshape(maps1, size(maps1,1)*size(maps1,2), size(maps1,3));
    maps2 = reshape(maps2, size(maps2,1)*size(maps2,2), size(maps2,3));

%     figure
%     subplot(2,1,1)
%     imagesc(maps1)
%     subplot(2,1,2)
%     imagesc(maps2)
    
    % Normalize
    for i = 1:size(maps1,1)
        m1 = maps1(i,:);
        m1 = m1 ./ sqrt(dot(m1,m1));
        maps1(i,:) = m1;
    end

    for i = 1:size(maps2,1)
        m2 = maps2(i,:);
        m2 = m2 ./ sqrt(dot(m2,m2));
        maps2(i,:) = m2;
    end

    % Compute the dot products
    dp = zeros(size(maps1,1), 1);
    for i = 1:size(maps1,1)
        dp(i) = dot(maps1(i,:), maps2(i,:));
    end
    dpAvg = nanmean(dp, 'all');
end % function