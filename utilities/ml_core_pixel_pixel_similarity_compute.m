function [ r ] = ml_core_pixel_pixel_similarity_compute(T1, T2, varargin)
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

    % Find matrix entries that are valid in both matrices
    % Valid entries have W(i,j) = 1
    a1 = find(p.Results.W1 == 1);
    a2 = find(p.Results.W2 == 1);
    a = intersect(a1, a2);

    % Compute the correlation coefficient
    %rr = corrcoef([T1(a), T2(a)]);

    % Store the value
    %r = rr(1,2);
    %r = sum(T1(a) .* T2(a), 'all');
    
    % Do it manually
    x = T1(a);
    x = reshape(x, 1, numel(x));
    y = T2(a);
    y = reshape(y, 1, numel(y));
    r = sum(x.*y) ./ sqrt( sum(x.*x) * sum(y.*y) );
    
end % function
