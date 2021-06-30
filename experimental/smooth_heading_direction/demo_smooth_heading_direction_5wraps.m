% Make angles that wrap multiple times to show how the smoothing is still
% done correctly.
omega = 10; % Angular velocity
t = linspace(0, 180, 1000);

theta = omega .* t;

% If the angle has wrapped around then subtract values until it is in 0 to
% 360 degrees.
for j = 1:length(theta)
   x = theta(j);
   while x >= 360
       x = x - 360;
   end
   theta(j) = x;
end

WS = 2;
a = theta * 2*pi/360;

% Unwrap so we can smooth
w = unwrap(a);

% Smooth
wrm = movmedian(w,[WS,WS]);

% Convert the smoothed angles back to [0, 360] degrees
arm = mod(wrm, 2*pi);
drm = rad2deg(arm);

% Show the results for comparison
figure
plot(t, theta, 'k-')
hold on
plot(t, drm, 'r-', 'linewidth', 2)
