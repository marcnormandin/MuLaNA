x = abs(z) >= 3;
gids = ml_util_group_points_v2(x);
validGids = gids;
validGids(x == 0) = [];
ugids = unique(validGids);

candidateIndices = [];
for i = 1:length(ugids)
   ugid = ugids(i);
   p = find(gids == ugid, 1, 'first');
   q = find(gids == ugid, 1, 'last');
   
   candidateIndices(:,i) = [p, q];
end

aboveIndices = find(x == 1);
figure
plot(z, 'k-')
hold on
plot(aboveIndices, z(aboveIndices), 'ro')
for iEvent = 1:size(candidateIndices,2)
    C = candidateIndices(:,iEvent);
    plot(C(1):C(2), z(C(1):C(2)), 'b-');
end
