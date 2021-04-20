function [cci] = ml_cai_estimate_spikes_indices(trace_raw)
    % cci are the spike indices into trace_raw
    
    mstd = movstd(trace_raw, 7);
    x = linspace(0, max(mstd), 1000);
    mmstd = mstd; % lognfit can't use values of 0
    mmstd(mmstd <= 0) = [];
    
    pt = prctile(x, 50); % 75 was last good value used
    mmstd(mmstd >= pt) = [];
    
    pHat = lognfit(mmstd);

    p = 1 - logncdf(mstd, pHat(1), pHat(2));
    ci = find(p <= 0.01);
    
    % reduce to only those that are consecutive and the trace is increasing
    cci = [];
    for i = 1:length(ci)-2
        % Must be 3 consecutive
        if ci(i+2)-1 == ci(i+1) && ci(i+1)-1 == ci(i)
            % Must all be increasing
            if trace_raw(ci(i+2)) >= trace_raw(ci(i+1)) && trace_raw(ci(i+1)) >= trace_raw(ci(i)) && trace_raw(ci(i)) > 0
                cci = [cci, ci(i)];
            end
        end
    end
end