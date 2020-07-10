function [groups] = helper_bfo_percell_get_groups(perCell)
    fn = fields(perCell);
    t = strfind(fn, 'prob_');
    inds = [];
    for i = 1:length(t)
        if length(t{i}) > 0
            inds(end+1) = i;
        end
    end
    groups = {};
    for i = inds
        g = fn{i};
        s = split(g, '_');
        groups{end+1} = s{2:end};
    end
end % function