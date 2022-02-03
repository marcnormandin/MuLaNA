function [y, N] = ml_alg_threshold_timeseries(x, threshold, minNum)
    % This function applies the threshold to the array x, and then
    % classifies portions as stable or unstable based on if the data is
    % above or below for the minNum number of times
    
    % Threshold the data
    M = x;
    M(x >= threshold) = 1; % Above or equal to threshold
    M(x < threshold) = 0; % Below threshold

    % Assign ids to the regions
    gids = ml_util_group_points_v2(M);

    % Form a frequency count of the group ids
    uniqueGids =  1:max(gids);
    edges = [uniqueGids, max(gids)+1];
    hc = histcounts(gids, edges);

    % These are unstable
    uniqueUnstableGids = uniqueGids(hc < minNum);

    % These are stable
    uniqueStableGids = uniqueGids(hc >= minNum);

    N = M; % set unstable to nan
    N(ismember(gids, uniqueUnstableGids)) = nan;

    y = [];
    y.above = [];
    y.below = [];
    y.unstable = [];
    t = 1:length(x);
    
    for i = 1:length(uniqueStableGids)
        sgid = uniqueStableGids(i);
        inds = find(gids == sgid);
        i1 = inds(1);
        i2 = inds(end);

        if M(i1) == 1 % above
            k = length(y.above) + 1;
            y.above{k,2} = x(i1:i2);
            y.above{k,1} = t(i1:i2);
        else % below
            k = length(y.below) + 1;
            y.below{k,2} = x(i1:i2);
            y.below{k,1} = t(i1:i2);
        end
    end
    
    
        for i = 1:length(uniqueUnstableGids)
            sgid = uniqueUnstableGids(i);
            inds = find(gids == sgid);
            i1 = inds(1);
            i2 = inds(end);

            k = length(y.unstable) + 1;
            y.unstable{k,2} = x(i1:i2);
            y.unstable{k,1} = t(i1:i2);
        end
    
        

end % function
