function [tDup, nDup] = men_timestamp_find_duplicates( t )

u = unique(t);
[n,bin] = histc(t, u);
ix = find(n > 1);

% The value that is duplicated
tDup = u(ix);

% The number of instances of the value
nDup = n(ix);

end % function

