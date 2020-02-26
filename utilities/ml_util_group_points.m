function gids = group_points(x, maxsep)

dx = diff(x);

gids = zeros(1,length(x));
k = 1;
gids(1) = 1;

for i = 1:length(dx)
    if dx(i) <= maxsep
        gids(i+1) = k;
    else
        k = k + 1;
        gids(i+1) = k;
    end
end

end