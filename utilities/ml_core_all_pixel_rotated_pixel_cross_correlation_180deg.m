function [r] = ml_core_all_pixel_rotated_pixel_cross_correlation_180deg(T1, T2, varargin)
    p = inputParser;
    p.CaseSensitive = false;

    checkmatrix = @(x) isnumeric(x);
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

    numRotations = 2; % 0, 180 degrees
    r = zeros(1,numRotations);
    
    % 0 degrees (no rotation)
    r(1) = ml_core_pixel_pixel_similarity_compute( T1, T2, 'W1', p.Results.W1, 'W2', p.Results.W2 );

    % 180 degrees (2 x 90 degrees)
    r(2) = ml_core_pixel_pixel_similarity_compute( T1, rot90(T2, 2), 'W1', p.Results.W1, 'W2', rot90(p.Results.W2, 2) );
        
end % function
