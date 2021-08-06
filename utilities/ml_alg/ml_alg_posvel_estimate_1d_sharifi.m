function [yfit, vel] = ml_alg_posvel_estimate_1d_sharifi(y, T, dmax)
% This is based on the paper:
% Discrete-Time Adaptive Windowing for Velocity Estimation,
% by Janabi-Sharifi et al, IEEE Transcation on Control System Technology
% Vol 6, November, 2000.

    yfit = y;
    vel = zeros(1,length(y));
    for k = 2:length(y)
       for i = 1:(k-1)
           % My 'i' is his 'n'

           
           % Check all intermediate value that they are within the banded line
           inds = (k-i+1):(k-1); % index to simply the math
           yest = zeros(1, length(inds));
           ytrue = zeros(1, length(inds));
           
           % Equation 14
           %b = (y(k) - y(k-i)) / (i*T);
           
           % Equation 17. Author says that this is more accurate.
           b = 0;
           for n = 0:i
               b = b + i*y(k-n) - 2*n*y(k-n);
           end
           b = b ./ (T*i*(i+1)*(i+2)/6);
           
           for m = 1:length(inds)
               yest(m) = y(k-i) + b*m*T;
               ytrue(m) = y(inds(m));
           end
           error = abs(ytrue-yest);
           if any(error > dmax)
               break;
           end

           % update the intermediate values since they are the best found
           for m = 1:length(inds)
               yfit(inds(m)) = yest(m);
           end

           % The estimate of the velocity (b_n).
           vel(k) = b;
       end
    end
end % function