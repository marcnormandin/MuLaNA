

c = distinguishable_colors(25);
p = 2; q = 3; k = 1;
figure
ax(1) = subplot(p,q,k);
k = k + 1;
plot(d.ts_ms, d.x, 'k.-')
hold on
plot(d.spike_ts_ms, d.spike_x, 'ro');
plot(d.spike_ts_ms(d.passedSpeedSpikei), d.spike_x(d.passedSpeedSpikei), 'ro', 'markerfacecolor', 'r')
grid on
grid minor
ylabel('y(t)')
axis tight

ax(2) = subplot(p,q,4);
k = k + 1;
plot(d.ts_ms, d.y, 'k.-')
hold on
plot(d.spike_ts_ms, d.spike_y, 'ro');
plot(d.spike_ts_ms(d.passedSpeedSpikei), d.spike_y(d.passedSpeedSpikei), 'ro', 'markerfacecolor', 'r')
grid on
grid minor
ylabel('y')
xlabel('t [ms]')
axis tight

linkaxes(ax, 'x')


bx(1) = subplot(p,q,[2,3,5,6]);
plot(d.x, d.y, 'k.-')
hold on
plot(d.spike_x, d.spike_y, 'bo', 'markerfacecolor', 'b', 'markersize', 10)
plot(d.spike_x(d.passedSpeedSpikei), d.spike_y(d.passedSpeedSpikei), 'ro', 'markerfacecolor', 'r')
grid on
grid minor
xlabel('x')
ylabel('y')
axis equal tight
