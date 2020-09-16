function [sfp, i3, i1] = ml_core_remove_zero_padding(sfp)
% removes any margins of all zeros from a matrix

    % Remove the left margin
    s = sum(sfp, 1);
    i1 = find(s ~= 0, 1, 'first');
    if ~isempty(i1)
        if i1 > 1
            i1 = i1 - 1;
        end

        sfp(:, 1:i1) = []; % remove left zero columns
    end

    % Remove the right zero columns
    s = sum(sfp,1);
    i2 = find(s == 0, 1, 'first');
    if ~isempty(i2)
        sfp(:, i2:end) = [];
    end

    % Remove the top zero rows
    s = sum(sfp,2);
    i3 = find(s ~= 0, 1, 'first');
    if ~isempty(i3)
        if i3 > 1
            i3 = i3 - 1;
        end
        sfp(1:i3, :) = [];
    end

    % Remove the bottom zero rows
    s = sum(sfp,2);
    i4 = find(s == 0, 1, 'first');
    if ~isempty(i4)
        sfp(i4:end, :) = [];
    end
end % function
