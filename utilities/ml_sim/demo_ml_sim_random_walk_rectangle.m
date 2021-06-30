% 2021-06-04: I wrote this code to test the path simulation code. The path
% simulation code performs a random walk with intermitent attraction to one
% of the 4 cups so that the paths are more realistic to what we see with
% real data.
close all
clear all
clc

arena_width_cm = 20;
arena_height_cm = 30;

boundsx_cm = [0, arena_width_cm];
boundsy_cm = [0, arena_height_cm];
totalTime_s = 180;
samplingRate_hz = 20;

[t_s, pos_x_cm, pos_y_cm] = ml_sim_random_walk_rectangle(boundsx_cm, boundsy_cm, totalTime_s, samplingRate_hz);


% Plot the path (no animation)
figure
plot(pos_x_cm, pos_y_cm, 'k-')
axis([boundsx_cm(1), boundsx_cm(2), boundsy_cm(1) boundsy_cm(2)])
axis equal
set(gca, 'ydir', 'reverse')


%% Plot the path with an animation
numSamples = length(t_s);
figure
for iSample = 1:numSamples
    hold off
    
    plot(pos_x_cm(1:iSample), pos_y_cm(1:iSample), 'k-')
    hold on
    plot(pos_x_cm(iSample), pos_y_cm(iSample), 'ro', 'markerfacecolor', 'r', 'markersize', 2)
    axis([boundsx_cm(1), boundsx_cm(2), boundsy_cm(1) boundsy_cm(2)])
    axis equal
    set(gca, 'ydir', 'reverse')
    drawnow
end

%%
