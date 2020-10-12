close all
clear all
clc

%function demo_hasselmo_function()
%a = 100;
%poly = [0 0; a, 0; a, a; 0, a];

% Define the polygon/arena
a = [0, 20];
b = [0, 0];
c = [30, 0];
d = [30, 20];
refCanPts = [a(1), b(1), c(1), d(1); a(2), b(2), c(2), d(2)];
poly = refCanPts';

% Mouse location
mousePosition = [10 10];
% Mouse heading direction in degrees
mouseHeadingDeg = 0;

% Define the angles to compute distances to
mouseEgocentricAngles = 0:1:180; % 0 and 180 are pairs, so only use one

[allAngles, allDistances] = ml_cai_egocentric_compute_distances(mousePosition, mouseHeadingDeg, mouseEgocentricAngles, poly);
