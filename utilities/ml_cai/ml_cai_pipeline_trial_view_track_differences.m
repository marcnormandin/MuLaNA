function [h] = ml_cai_pipeline_trial_view_track_differences(folder)
if isempty(folder)
    folder = uigetdir();
end

tfn = fullfile(folder, 'behav_track_vid.hdf5');
bfn = fullfile(folder, 'behavcam_background_frame.png');
svcfn = fullfile(folder, 'behaviour_scope_videocoords.mat');
sfn = fullfile(folder, 'scope.hdf5');

BG = imread(bfn);

% From the tracker
x = h5read(tfn, '/pos_vid_pixel_i');
y = h5read(tfn, '/pos_vid_pixel_j');
q = h5read(tfn, '/quality');
t = double(h5read(tfn, '/timestamp_ms')) / (1.0*10^3);

% After data conditioning
svc = load(svcfn, 'behaviour_scope_videocoords');
svc = svc.behaviour_scope_videocoords;
ix = svc.pos(:,1);
iy = svc.pos(:,2);
it = double(h5read(sfn, '/timestamp_ms')) / (1.0*10^3);

qthreshold = 0;
qbadidx = find(q > qthreshold);
bx = x(qbadidx);
by = y(qbadidx);
bt = t(qbadidx);

h = figure('Name', folder, 'Position', get(0,'Screensize'));
p = 4; q = 2;
bx(1) = subplot(p,q,[1,3]);
imshow(BG);
hold on
plot(x,y,'b-')
plot(bx, by, 'r.')
title('From Tracker')

bx(2) = subplot(p,q,[2,4]);
imshow(BG);
hold on
plot(ix,iy,'g-')
title('Data conditioned')

linkaxes(bx, 'xy')


ax(1) = subplot(p,q,[5]);
plot(t, x, 'k.')
hold on
plot(bt, bx, 'ro')
plot(it, ix, 'g.')
axis tight
grid on
ylabel('x [px]')

ax(2) = subplot(p,q,[6]);
plot(t(1:end-1), diff(x), 'k.')
hold on
plot(bt(1:end-1), diff(bx), 'ro')
plot(it(1:end-1), diff(ix), 'g.')
axis tight
grid on
ylabel('dx [px]')

ax(3) = subplot(p,q,[7]);
plot(t, y, 'k.')
hold on
plot(bt, by, 'ro')
plot(it, iy, 'g.')
axis tight
grid on
ylabel('y [px]')
xlabel('t [ms]')

ax(4) = subplot(p,q,[8]);
plot(t(1:end-1), diff(y), 'k.')
hold on
plot(bt(1:end-1), diff(by), 'ro')
plot(it(1:end-1), diff(iy), 'g.')
axis tight
grid on
ylabel('dy [px]')
xlabel('t [ms]')

linkaxes(ax, 'x')

end % function
