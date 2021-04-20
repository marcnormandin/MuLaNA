function [t] = get_path_bin_transitions(movement, cm_per_bin)
    if strcmpi( movement.arenaShape, 'rectangle' )
        nbinsx = ceil(movement.arena.x_length_cm / cm_per_bin + 1);
        nbinsy = ceil(movement.arena.y_length_cm / cm_per_bin + 1);

        maxx_cm = movement.arena.x_length_cm;
        maxy_cm = movement.arena.y_length_cm;
    else
        error('Invalid shape')
    end
    boundsx = [0, maxx_cm];
    boundsy = [0, maxy_cm];

    % Discretize the position data so we can bin it
    [x_bounded, y_bounded, xi, yi, xedges, yedges] = ...
    ml_core_compute_binned_positions(movement.x_cm, movement.y_cm, boundsx, boundsy, nbinsx, nbinsy);

    inds = sub2ind([nbinsy, nbinsx], yi, xi);
    gids = ml_util_group_points_v2(inds);
    
    t = {};
    uinds = unique(inds);
    for i = 1:length(uinds)
       ind = uinds(i);
       j = find(inds == ind);
       gid = unique(gids(j));
       
%        gstart_timestamps_ms = [];
%        gstop_timestamps_ms = [];
       
       for k = 1:length(gid)
           p = length(t) + 1;
           l1 = find(gids == gid(k), 1, 'first');
           l2 = find(gids == gid(k), 1, 'last');
           gstart_timestamps_ms = movement.timestamps_ms(l1);
           gstop_timestamps_ms = movement.timestamps_ms(l2);
           
           [t(p).yi, t(p).xi] = ind2sub([nbinsy, nbinsx], ind);
           t(p).ind = ind;
           t(p).gid = gid(k);
           t(p).visit_number = k;
           t(p).gstart_timestamps_ms = gstart_timestamps_ms;
           t(p).gstop_timestamps_ms = gstop_timestamps_ms;
       end
       
       
    end
    
end % function