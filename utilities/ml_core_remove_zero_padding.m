function [compact, row, col] = ml_core_remove_zero_padding(sfp)
% removes any margins of all zeros from a matrix
% row is how many rows of zeros and col is how many cols of zeros

    % Check for edge cases that everything is zero
    if all(sfp == 0, 'all')
        compact = [];
        row = nan;
        col = nan;
        return
    end
    
    % Check for edge cases that everything is zero
%     if all(sfp == 0, 'all')
%         sfp = [];
%         row = nan;
%         col = nan;
%         %return
%     end

    bw = sfp ~= 0;
    
    sx = sum(bw, 1);
    sx(sx ~= 0) = 1;
    
    j1 = find(sx == 1, 1, 'first');
    j2 = find(sx == 1, 1, 'last');
    
    sy = sum(bw, 2);
    sy(sy ~= 0) = 1;
    
    i1 = find(sy == 1, 1, 'first');
    i2 = find(sy == 1, 1, 'last');
    
    compact = sfp(i1:i2, j1:j2);
    
    %width = j2-j1+1;
    %height = i2-i1+1;
    
    row = i1-1;
    col = j1-1;
    

%     % Remove the left margin
%     s = sum(abs(sfp), 1);
%     i1 = find(s ~= 0, 1, 'first');
%     if ~isempty(i1)
%         if i1 > 1
%             i1 = i1 - 1;
%         end
% 
%         sfp(:, 1:i1) = []; % remove left zero columns
%     end
% 
%     % Remove the right zero columns
%     s = sum(abs(sfp),1);
%     i2 = find(s > 0, 1, 'last');
%     if ~isempty(i2)
%         sfp(:, i2+1:end) = [];
%     end
% 
%     % Remove the top zero rows
%     s = sum(abs(sfp),2);
%     i3 = find(s ~= 0, 1, 'first');
%     if ~isempty(i3)
%         if i3 > 1
%             i3 = i3 - 1;
%         end
%         sfp(1:i3, :) = [];
%     end
% 
%     % Remove the bottom zero rows
%     s = sum(abs(sfp),2);
%     i4 = find(s > 0, 1, 'last');
%     if ~isempty(i4)
%         sfp(i4+1:end, :) = [];
%     end
%     
%     row = i3;
%     col = i1;
end % function
