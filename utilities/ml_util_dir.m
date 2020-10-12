function [d] = ml_util_dir(s)
    d = dir(s);
    d = d(~ismember({d.name}, {'.', '..'}));
end