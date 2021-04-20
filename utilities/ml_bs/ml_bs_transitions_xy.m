function [trans, xj, yj] = ml_bs_transitions_xy(bs, x, y)

    [xj, yj] = ml_bs_discretize_xy(bs, x, y);
    inds = sub2ind([bs.ny, bs.nx], yj, xj);
    gids = ml_util_group_points_v2(inds);
    
    trans = {};
    uinds = unique(inds);
    for i = 1:length(uinds)
       ind = uinds(i);
       j = find(inds == ind);
       gid = unique(gids(j));
              
       for k = 1:length(gid)
           p = length(trans) + 1;
           l1 = find(gids == gid(k), 1, 'first');
           l2 = find(gids == gid(k), 1, 'last');
           
           [trans(p).yi, trans(p).xi] = ind2sub([bs.ny, bs.nx], ind);
           trans(p).ind = ind;
           trans(p).gid = gid(k);
           trans(p).visit_number = k;
           trans(p).first_index = l1;
           trans(p).last_index = l2;
       end
    end
end
