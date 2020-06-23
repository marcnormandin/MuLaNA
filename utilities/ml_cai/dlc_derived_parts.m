clear all
close all
clc

trackedParts = ml_cai_dlc_to_tracked_parts(pwd);

iEarLeft = 1;
iEarRight = 2;
iMiniscopeLed = 3;
iHip = 4;
iTailBase = 5;

dx = trackedParts(iEarRight).x - trackedParts(iEarLeft).x;
dy = trackedParts(iEarRight).y - trackedParts(iEarLeft).y;
thetaRad = atan2(dy, dx);
i = find(thetaRad < 0);
thetaRad(i) = thetaRad(i) + 2.0*pi; % change from -180, 180 to 0, 360
% now subtract 90 to get the perpendicular
thetaRad = thetaRad - pi/2.0;
i = find(thetaRad < 0);
thetaRad(i) = thetaRad(i) + 2.0*pi;

thetaDeg = rad2deg(thetaRad);



headCenter.x = (trackedParts(iEarLeft).x + trackedParts(iEarRight).x)/2.0;
headCenter.y = (trackedParts(iEarLeft).y + trackedParts(iEarRight).y)/2.0;
headCenter.p = (trackedParts(iEarLeft).p + trackedParts(iEarRight).p);

minThetaRad = atan2( trackedParts(iMiniscopeLed).y - headCenter.y, trackedParts(iMiniscopeLed).x - headCenter.x );
i = find( minThetaRad < 0 );
minThetaRad(i) = minThetaRad(i) + 2.0*pi;

minThetaDeg = rad2deg(minThetaRad);

A = 4;

headArrow.x = headCenter.x + A * cosd(thetaDeg);
headArrow.y = headCenter.y + A * sind(thetaDeg);

minArrow.x = headCenter.x + A * cosd(minThetaDeg);
minArrow.y = headCenter.y + A * sind(minThetaDeg);

hindCenter.x = (trackedParts(iHip).x + trackedParts(iTailBase).x) / 2.0;
hindCenter.y = (trackedParts(iHip).y + trackedParts(iTailBase).y) / 2.0;

%indx = 1000:1100;
indx = 1:length(thetaDeg);

figure
%plot(trackedParts(iEarLeft).x(1), trackedParts(iEarLeft).y(1), 'go', 'markerfacecolor', 'k', 'markeredgecolor', 'k')
hold on
%plot(trackedParts(iEarRight).x(1), trackedParts(iEarRight).y(1), 'ro', 'markerfacecolor', 'k', 'markeredgecolor', 'k')
%plot(trackedParts(iTailBase).x(1), trackedParts(iTailBase).y(1), 'bo', 'markerfacecolor', 'k', 'markeredgecolor', 'k')

hold on

% plot(trackedParts(iEarLeft).x(indx), trackedParts(iEarLeft).y(indx), 'g-')
% hold on
% plot(trackedParts(iEarRight).x(indx), trackedParts(iEarRight).y(indx), 'r-')
%plot(trackedParts(iTailBase).x(indx), trackedParts(iTailBase).y(indx), 'b-', 'markerfacecolor', 'b')

%plot(trackedParts(iHip).x(indx), trackedParts(iHip).y(indx), 'm-')

cmap = colormap('hsv');
thetaColourMap = linspace(1, length(cmap), 360);
thetaColourIndex = zeros(1,length(thetaDeg));
for iTheta = 1:length(thetaDeg)
    thetaColourIndex(iTheta) = thetaColourMap(ceil(thetaDeg(iTheta)));
end
%thetaColourIndex = thetaColourMap(round(thetaDeg(1)));
thetaColour = zeros(length(thetaDeg),3);
for iTheta = 1:length(thetaDeg)    
    thetaColour(iTheta,:) = cmap( ceil(thetaColourIndex(iTheta)), : );
end

% for i = indx
%     plot(headCenter.x(i), headCenter.y(i), 'o', 'color', thetaColour(i,:), 'markerfacecolor',thetaColour(i,:))
% end
% colorbar
%scatter(headCenter.x(indx), headCenter.y(indx), thetaColour(indx))
colormap('hsv');
caxis([0,360])

ax(1) = subplot(1,2,1);
scatter(headCenter.x(indx), headCenter.y(indx), 4, thetaDeg(indx));
hold on
plot(headCenter.x(indx), headCenter.y(indx),'-', 'color', [0 0 0 0.2])
hcb = colorbar('YTick', [0, 90, 180, 270, 360], 'YTickLabel', {'Right', 'Bottom', 'Left', 'Top', 'Right'});
title('Using Ears')
axis equal tight
set(gca, 'ydir', 'reverse');

ax(2) = subplot(1,2,2);
scatter(headCenter.x(indx), headCenter.y(indx), 4, minThetaDeg(indx))
hcb = colorbar('YTick', [0, 90, 180, 270, 360], 'YTickLabel', {'Right', 'Bottom', 'Left', 'Top', 'Right'});
hold on
plot(headCenter.x(indx), headCenter.y(indx),'-', 'color', [0 0 0 0.2])
title('Using Miniscope LED')
axis equal tight
set(gca, 'ydir', 'reverse')

linkaxes(ax, 'xy')

%plot(hindCenter.x(indx), hindCenter.y(indx), 'm-')

% for i = indx
%     plot([trackedParts(iEarLeft).x(i), trackedParts(iEarRight).x(i)], [trackedParts(iEarLeft).y(i), trackedParts(iEarRight).y(i)], 'k-')
%     
%     plot([headCenter.x(i), headArrow.x(i)], [headCenter.y(i), headArrow.y(i)], 'm-', 'linewidth', 4)
%     plot(headArrow.x(i), headArrow.y(i), 'k^')
%     
%     
%     %plot([headCenter.x(i), trackedParts(iMiniscopeLed).x(i)], [headCenter.y(i), trackedParts(iMiniscopeLed).y(i)], 'g-', 'linewidth', 4)
% 
%     plot([headCenter.x(i), minArrow.x(i)], [headCenter.y(i), minArrow.y(i)], 'g-', 'linewidth', 4)
%     plot(minArrow.x(i), minArrow.y(i), 'k^');
%     %plot(trackedParts(iMiniscopeLed).x(i), trackedParts(iMiniscopeLed).y(i), 'k^')
% end

%set(gca, 'ydir', 'reverse')
%axis equal
%grid on
%xlabel('x')
%ylabel('y')


figure
plot(minThetaDeg, 'r.-')
hold on
plot(thetaDeg, 'g.-')
legend({'Miniscope LED', 'Ears'})
grid on
