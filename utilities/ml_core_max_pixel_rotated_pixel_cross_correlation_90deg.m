function [v, vind] = ml_core_max_pixel_rotated_pixel_cross_correlation_90deg(T1, T2, varargin)
    p = inputParser;
    p.CaseSensitive = false;

    checkmatrix = @(x) isnumeric(x) && size(x,1) == size(x,2);
    addRequired(p, 'T1', checkmatrix);
    addRequired(p, 'T2', checkmatrix);
    
    % By default use all of the matrix entries
    checkweight1 = @(x) isnumeric(x);
    addParameter(p, 'W1', ones(size(T1)), checkweight1);
    checkweight2 = @(x) isnumeric(x);
    addParameter(p, 'W2', ones(size(T2)), checkweight2);
    
    addParameter(p, 'verbose', false, @islogical);

    parse(p, T1, T2, varargin{:});
    
    % Validate the inputs
    if size(T1) ~= size(T2)
        error('Both matrices must be the same size.')
    end
    if size(p.Results.W1) ~= size(T1) 
        error('The weight (1/0) matrix must be the same size as the matrices themselves.')
    end
    if size(p.Results.W2) ~= size(T2) 
        error('The weight (1/0) matrix must be the same size as the matrices themselves.')
    end

    numRotations = 4; % 0, 90, 180, 270 degrees
    r = zeros(1,numRotations);
    for k = 1:numRotations
        % Rotate T2 counter-clockwise
        T2Rot = rot90(T2, k-1);
        W2Rot = rot90(p.Results.W2, k-1);
        
        r(k) = ml_core_pixel_pixel_cross_correlation_compute(T1, T2Rot, 'W1', p.Results.W1, 'W2', W2Rot);
    end

    % Find the maximum correlation
    [v,vind] = max(r);
       
end % function
