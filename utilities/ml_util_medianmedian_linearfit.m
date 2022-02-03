function [a,b, y_fit] = ml_util_medianmedian_linearfit(x,y)
    % This perform a median-median linear fit to the points x, y
    % and returns the intercept 'a' and slope 'b' such that
    % y_fit = a + b*x_data
    
    N = numel(x);
    if numel(y) ~= N
        error('Length of x and y must be the same.');
    end
    
    % Split data into three sets: left, middle, and right
    N3 = floor(N/3);
    inds = [1,N3; N3+1, 2*N3; 2*N3+1, N];

    xL = nanmedian(x(inds(1,1):inds(1,2)));
    xM = nanmedian(x(inds(2,1):inds(2,2)));
    xR = nanmedian(x(inds(3,1):inds(3,2)));
    
    yL = nanmedian(y(inds(1,1):inds(1,2)));
    yM = nanmedian(y(inds(2,1):inds(2,2)));
    yR = nanmedian(y(inds(3,1):inds(3,2)));

    % slope
    b = (yR - yL) ./ (xR - xL);
    
    % intercept
    a = ((yL - b*xL)+(yM - b*xM) + (yR - b*xR))/3;
    
    % fit
    y_fit = a + b * x;
end
