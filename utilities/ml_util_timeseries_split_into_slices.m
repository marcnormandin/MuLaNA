function [slice] = ml_util_timeseries_split_into_slices( ts_ms, x, slice_separation_threshold_ms )
    % Check that the inputs are fine
    if slice_separation_threshold_ms <= 0
        error('The slice separation threshold must be >= 0, but is (%d).', slice_separation_threshold_ms);
    end
    
    
    inds = ml_util_timeseries_find_slice_indices(ts_ms, slice_separation_threshold_ms);

    numSlices = size(inds,2);
    slice = cell(numSlices,1);
    for i = 1:numSlices
        p = inds(1,i);
        q = inds(2,i);

        slice{i}.numSamples = (q-p)+1;

        slice{i}.startIndex = p;
        slice{i}.stopIndex = q;
        slice{i}.timeStamps_ms = ts_ms(p:q);
        slice{i}.x = x(p:q);
        slice{i}.slice_id = i;
    end
end
