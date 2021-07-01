function [slice] = ml_nlx_nvt_split_into_slices( nvtFilename, nvt_file_slice_separation_threshold_s )
    % Check that the inputs are fine
    if ~isfile( nvtFilename )
        error('The required file (%s) does not exist.\n', nvtFilename);
    end
    if nvt_file_slice_separation_threshold_s <= 0
        error('The slice separation threshold must be >= 0, but is (%d).', nvt_file_slice_separation_threshold_s);
    end
    
    [TimeStamps_mus, ExtractedX, ExtractedY, ExtractedAngle, Targets, Points, Header] = ml_nlx_nvt_load( nvtFilename );
    
    inds = ml_nlx_nvt_find_slice_indices(TimeStamps_mus, nvt_file_slice_separation_threshold_s);

    numSlices = size(inds,2);
    slice = cell(numSlices,1);
    for i = 1:numSlices
        p = inds(1,i);
        q = inds(2,i);

        slice{i}.numSamples = (q-p)+1;

        slice{i}.startIndex = p;
        slice{i}.stopIndex = q;
        slice{i}.timeStamps_mus = TimeStamps_mus(p:q);
        slice{i}.extractedX = ExtractedX(p:q);
        slice{i}.extractedY = ExtractedY(p:q);
        slice{i}.extractedAngle = ExtractedAngle(p:q);
        slice{i}.targets = Targets(:,p:q);
        slice{i}.points = Points(:,p:q);
        slice{i}.header = Header; % full header
        slice{i}.slice_id = i;
    end
end
