tmp = load(fullfile('/work/muzziolab/PROJECTS/two_contexts_CA1/tetrodes/recordings/feature_rich/AK42_CA1/d7/trial_1_arenaroi.mat'));
%tmp = load(fullfile('/work/muzziolab/PROJECTS/two_contexts_CA1/tetrodes/recordings/feature_poor/MG1_CA1/s8/trial_1_arenaroi.mat'));

arenaroi = tmp.arenaroi;

%%
x = trial.extractedX;
dx = [0, diff(x)];
y = trial.extractedY;
dy = [0, diff(y)];
t = trial.timeStamps_mus ./ 10^6;

K = 5;

inside = inpolygon(x,y, arenaroi.xVertices, arenaroi.yVertices);

xin = x(inside);
yin = y(inside);
tin = t(inside);

close all


figure
subplot(1,2,1)
ind = find(dx > K);
plot(t(ind), x(ind), 'r.')
hold on
ind = find(dx <= K);
plot(t(ind), x(ind), 'g.')

plot(t(inside), x(inside), 'ko')

subplot(1,2,2)
hist(x, 100)


dxin = [0, diff(xin)];
bi = find(dxin > K);

figure
subplot(1,2,1)
plot(tin, xin, 'k-.')
hold on
plot(tin(bi), xin(bi), 'rs', 'markerfacecolor', 'r')

subplot(1,2,2)
hist(dxin, 100)
