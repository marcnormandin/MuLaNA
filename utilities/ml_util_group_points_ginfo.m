function [ ginfo, gids ] = ml_util_group_points_ginfo(x)
    % x should be an array of numbers. Whenever numbers are not the same as
    % their neighbours a new group will be created to represent them.
    %
    % Can be called on an array that has been thresholded resulting in an
    % array of zeros and ones.
    
    gids = ml_util_group_points_v2(x);

    ugids = unique(gids);
    nGids = length(ugids);

    ginfo = [];
    for iGid = 1:nGids
        gid = ugids(iGid);
        i1 = find(gids == gid, 1, 'first');
        i2 = find(gids == gid, 1, 'last');
        ginfo(iGid).gid = gid;
        ginfo(iGid).indexFirst = i1;
        ginfo(iGid).indexLast = i2;
        ginfo(iGid).nSamples = i2 - i1 + 1;
    end % iGid
end
