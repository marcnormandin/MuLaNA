rots = extra;

rm = zeros(4,4);
p = (1:4)';
for k = 1:4
   rm(:,k) = circshift(p,k-1); 
end


gbest = cell(maxId,1);
for gid = 1:maxId
    gbest{gid} = [];
    for iTrial1 = 1:numTrials
        r1 = rots(gid, iTrial1);
        if isnan(r1)
            continue;
        end
        
        for iTrial2 = iTrial1+1:numTrials
            if iTrial1 == iTrial2
                continue; % skip
            end
            
            r2 = rots(gid,iTrial2);
            
            if isnan(r2)
                continue;
            end
            
            
            
            p = gbest{gid};
            p(end+1) = rm(r1, r2);
            gbest{gid} = p;
        end
    end
end
gall = [];
for gid = 1:maxId
    gall = [gall, gbest{gid}];
end
hc1 = histcounts(gall, 1:5);
hc1 = hc1 ./ sum(hc1) * 100;
figure
bar(hc1)
title('Method 1')


gba = [];
for gid = 1:maxId
    x = gbest{gid};
    hc = histcounts(x, 1:5);
    mi = find(hc == max(hc));
    gba = [gba, mi];
end
hc2 = histcounts(gba, 1:5);
hc2 = hc2 ./ sum(hc2) * 100;
figure
bar(hc2)
title('Method 2')