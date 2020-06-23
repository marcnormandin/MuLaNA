function [quality] = ml_cai_quality_all_one_led(t, x1, varargin)

    p = inputParser;
    p.CaseSensitive = false;
    
    check_t = @(x) isnumeric(x);
    addRequired(p, 't', check_t);
    
    check_x1 = @(x) size(x,2) == 2 && isnumeric(x);
    addRequired(p,'x1', check_x1);

    N = length(x1);
    addParameter(p, 'differenceFactor', 4, @isscalar);
    addParameter(p, 'qtracker', zeros(N,1), @isnumeric);
    
    addParameter(p,'verbose', false, @islogical);
        
    parse(p, t, x1, varargin{:});
    
    if size(t,1) ~= size(x1,1)
        error('The time array must be as long as the behaviour arrays.');
    end
    
    if p.Results.verbose
        fprintf('Using the following quality settings (two leds):\n');
        disp(p.Results.verbose);
    end
    
    % Check each coordinate of each LED
    q11 = ml_cai_quality_led_position_difference(x1(:,1), p.Results.differenceFactor);
    q12 = ml_cai_quality_led_position_difference(x1(:,2), p.Results.differenceFactor);
    
    % For for duplicates in the time value (which happen!)
    qdup = zeros(size(t));
    [tDup, nDup] = men_timestamp_find_duplicates( t );
    for i = 1:length(tDup)
        dupIndices = find(t == tDup(i));
        for j = 1:length(dupIndices)
            qdup(dupIndices(j)) = qdup(dupIndices(j)) + 1;
        end
    end
    
    % Sum all of the quality arrays since 0 means good
    quality = q11 + q12 + qdup + p.Results.qtracker;
    
end % function
