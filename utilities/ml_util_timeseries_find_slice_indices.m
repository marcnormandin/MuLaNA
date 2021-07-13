function [sliceIndices] = ml_util_timeseries_find_slice_indices( ts_ms, slice_separation_threshold_ms)
% This returns indices into the array ts_ms such that it can be split into
% slices where the slices are separated by more than
% slice_separation_threshold_s seconds.

% Convert the threshold in second to milliseconds
endTrialIfGapMoreThanThis = slice_separation_threshold_ms;

breaks = find(diff(ts_ms) > endTrialIfGapMoreThanThis);
borders = [1 breaks+1 length(ts_ms)];
inds = zeros(2, length(borders)-1);
N = length(borders)-1;
for i = 1:N
    inds(1,i) = borders(i);
    
    % We have to treat the final slice differently.
    if i < N
        inds(2,i) = borders(i+1)-1;
    else
        inds(2,i) = borders(i+1);
    end
end

sliceIndices = inds;

end % function

