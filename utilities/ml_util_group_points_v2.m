function gids = ml_util_group_points_v2(x)
    gids = zeros(1,length(x));
    k = 1;

    gids(1) = k;
    
    for i = 2:length(x)
        if x(i) ~= x(i-1)
            k = k + 1;
        end
        gids(i) = k;
    end

end
