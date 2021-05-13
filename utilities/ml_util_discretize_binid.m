function binId = ml_util_discretize_binid(x, cm_per_bin)
    % This discretizes the values in x in terms of the cm_per_bin. A result
    % of 0 means the value is in [-cm_per_bin/2, +cm_per_bin/2]. Positive
    % bin values are to the right of the origin, and negative bin values
    % are to the left of the origin. Since values can be negative, to use
    % them to index into a matrix a minimum value must be added, but that
    % depends on the total points and matrix used.
    binId = floor((x-cm_per_bin/2)/cm_per_bin)+1;
    
    %binId = round((x-cm_per_bin/2)/cm_per_bin)+1; % doesnt work
end