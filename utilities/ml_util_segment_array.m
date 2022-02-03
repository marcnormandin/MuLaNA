function [segmentIndexRanges] = ml_util_segment_array(a, maxDifference)
    %% Splits an array of values into segments whose values in each
    %  segment dont differ by maxDifference.
    %
    % eg. t = [1     2     3     4     5     6     7     8    10    11    13    14    15    16    19    20]
    % 
    % segmentIndexRanges =
    %      1     8
    %      9    10
    %     11    14
    %     15    16

    da = diff(a);
    ind = find(da > maxDifference);

    numSegments = length(ind) + 1;
    segmentIndexRanges = zeros(numSegments, 2);
    for iSegment = 1:numSegments
        if iSegment == 1
            i = 1;
        else
            i = ind(iSegment-1)+1;
        end

        if iSegment == numSegments
            j = length(a);
        else
            j = ind(iSegment);
        end

        segmentIndexRanges(iSegment,:) = [i, j];
    end
    
end % function
