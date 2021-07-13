function [sliceIndices] = ml_nlx_nvt_find_slice_indices( nlxTimeStamps_mus, slice_separation_threshold_s)
% Convert the threshold in second to microseconds
endTrialIfGapMoreThanThis = slice_separation_threshold_s * 10^6;

breaks = find(diff(nlxTimeStamps_mus) > endTrialIfGapMoreThanThis);
borders = [1 breaks+1 length(nlxTimeStamps_mus)];
inds = zeros(2, length(borders)-1);
N = length(borders)-1;
for i = 1:N
    inds(1,i) = borders(i);
    
    % We have to treat the final trial differently.
    if i < N
        inds(2,i) = borders(i+1)-1;
    else
        inds(2,i) = borders(i+1);
    end
end

sliceIndices = inds;

end % function

