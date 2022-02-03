function [matchingRows] = ml_util_find_row_matches(x1, x2)
    % x1 and x2 should be cell arrays with the same number of columns and
    % strings as data
    matchingRows = []; %zeros(size(x1,1),2);
    for i = 1:size(x1,1)
        for j = 1:size(x2,1)
            isFound2 = true;
            for k = 1:size(x1,2)
                if ~strcmp(x1{i,k}, x2{j,k})
                    isFound2 = false;
                    break;
                end
            end
            if isFound2
                matchingRows(size(matchingRows,1)+1,:) = [i,j];
            end
        end
    end
end % function