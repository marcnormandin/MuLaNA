function [sfp] = ml_core_remove_zero_padding(sfp)
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
    i1 = find(s == 0, 1, 'first');
    if ~isempty(i1)
        sfp(:, i1:end) = [];
    end

    % Remove the top zero rows
    s = sum(sfp,2);
    i2 = find(s ~= 0, 1, 'first');
    if ~isempty(i2)
        if i2 > 1
            i2 = i2 - 1;
        end
        sfp(1:i2, :) = [];
    end

    % Remove the bottom zero rows
    s = sum(sfp,2);
    i2 = find(s == 0, 1, 'first');
    if ~isempty(i2)
        sfp(i2:end, :) = [];
    end
end % function
