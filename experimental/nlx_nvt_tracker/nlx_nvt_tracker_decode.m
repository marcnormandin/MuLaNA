nvtFilename = fullfile('/work/muzziolab/PROJECTS/two_contexts_CA1/tetrodes/recordings/feature_rich/AK42_CA1/d7', 'VT1.nvt');
[TimeStamps_mus, ExtractedX, ExtractedY, ExtractedAngle, Targets, Points, Header] = Nlx2MatVT(  nvtFilename, [1, 1, 1, 1, 1, 1], 1, 1, 1 );
% Use the offical neuralynx loader or use ours which removes possible
% duplicates made by neuraview when splitting data.

d = struct('reserved', [], 'pureRed', [], 'pureGreen', [], 'pureBlue', [], ...
    'yLocation', [], ...
    'intensity', [], 'rawRed', [], 'rawGreen', [], 'rawBlue', [], ...
    'xLocation', []);

close all

figure('position', get(0, 'screensize'))

for iFrame = 1:2000
    x = 0;
    y = 0;
    n = 0;
for i=1:50
%c = trial.targets(i,iFrame);
c = Points(i,iFrame);

d(i).reserved = bitget(c, 32, 'uint32');
d(i).pureRed = bitget(c, 31, 'uint32');
d(i).pureGreen = bitget(c, 30, 'uint32');
d(i).pureBlue = bitget(c, 29, 'uint32');

%d(i).yLocation = sum(bitset(0, find(bitget(c, 5:16, 'uint32')==1), 'uint32'));
d(i).yLocation = sum(bitget(c, 28:-1:17, 'uint32') .* 2.^[11:-1:0]);

d(i).intensity = bitget(c, 16, 'uint32');
d(i).rawRed = bitget(c, 15, 'uint32');
d(i).rawGreen = bitget(c, 14, 'uint32');
d(i).rawBlue = bitget(c, 13, 'uint32');

%d(i).xLocation = sum(bitset(0, find(bitget(c, 21:32, 'uint32')==1), 'uint32'));
d(i).xLocation = sum(bitget(c, 12:-1:1, 'uint32') .* 2.^[11:-1:0]);

if d(i).pureRed == 1 && d(i).pureGreen == 0
    plot(d(i).xLocation, d(i).yLocation, 'r.')
    x = x + d(i).xLocation;
    y = y + d(i).yLocation;
    n = n + 1;
elseif d(i).pureRed == 0 && d(i).pureGreen == 1
    plot(d(i).xLocation, d(i).yLocation, 'g.')
        x = x + d(i).xLocation;
    y = y + d(i).yLocation;
    n = n + 1;
elseif d(i).pureRed == 0 && d(i).pureGreen == 0 && d(i).intensity == 1
    plot(d(i).xLocation, d(i).yLocation, 'ko')
        x = x + d(i).xLocation;
    y = y + d(i).yLocation;
    n = n + 1;
end

hold on
xlim([250, 500])
ylim([250, 500])
grid on
end
if n ~= 0
    plot(x/n, y/n, 'bo', 'markerfacecolor', 'b', 'markersize', 20)
end
pause(0.01)
clf
end
set(gca, 'ydir', 'reverse')

