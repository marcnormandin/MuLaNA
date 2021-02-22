function [stats] = ml_cai_spatialfootprint_stats_compact(sfp)
    %sfp = ml_core_remove_zero_padding(sfp);
    % SFP must aleady be compact
    
    X = sfp;
    p = prctile(X(X ~= 0), 50);
    
    % M1
    BW = bwperim(X>0, 8);
    P = sum(BW == 1, 'all');
    A = sum(X>0, 'all');
    M1 = 4 * pi * A / P.^2;

    CC = bwconncomp(X >= p);
    numComponents = CC.NumObjects;

    % M2
    BW = bwperim(X>=p, 8);
    P = sum(BW == 1, 'all');
    A = sum(X>=p, 'all');
    M2 = 4 * pi * A / P.^2;
    
    M3 = (M1 + M2)/2;
    
    OA = sum(X>0, 'all') ./ numel(X);

    stats.C1 = M1;
    stats.C2 = M2;
    stats.circularity = M3;
    stats.numComponents = numComponents;
    stats.occupiedArea = OA;
    stats.size = max(size(X));
end % function