% Muzzio Lab, 2020-08-25
% Marc Normandin
% Demo written to show signal reconstruction from FFT
% without using ifft.

clear all
close all
clc

% our system's sampling rate
fs = 200;
N = 1000; % number of samples

% these are the sample times
sample_t = (0:N-1)/fs;

% these are the sample frequencies (of the Fourier transform)
sample_f = (0:N-1)*fs / N;

% Our signal will be composed of pure sinusoids of these frequencies
%f = [10, 30]; % might not be fourier frequencies
% use this for exact frequencies (perfect reconstruction)
f = [sample_f(20), sample_f(100)];

% and these amplitudes
a = [10, 14];
% the frequencies will not necessarily be those sampled by the FFT

% Make the pure signals for demonstration, and the combined signal
s_pure = zeros(length(f), N);
s_legend = cell(length(f)+1,1);
s_legend{1} = 'Combined';

for i = 1:length(f)
    s_pure(i,:) = a(i) * cos(2*pi*f(i)*sample_t); % no phase
    s_legend{i+1} = sprintf('f = %0.2f Hz', f(i));
end
s = sum(s_pure, 1);

% Compute the FFT
X = fft(s);
mag_X = abs(X);
phase_X = angle(X);

% reconstruct the signal from the fourier transform directly
recon_s = zeros(1,N);
for n = 1:N
    for k = 1:N/2
        recon_s(n) = recon_s(n) + mag_X(k) * cos(2*pi* (k-1) * (n-1) / N + phase_X(k)) * (2/N);
    end
end

p = 3; q = 1; r = 1;
figure

ax(r) = subplot(p,q,r);
r = r + 1;
plot(sample_t, s)
for i = 1:size(s_pure,1)
    hold on
    plot(sample_t, s_pure(i,:))
end
grid on
title('Signal and its components')
legend(s_legend)

bx(r) = subplot(p,q,r);
r = r + 1;
plot(sample_f, abs(X))
title('Fourier')
grid on

ax(r) = subplot(p,q,r);
r = r + 1;
plot(sample_t, s, 'b-', 'linewidth', 2)
hold on
plot(sample_t, recon_s, 'r-')
legend({'Original', 'Reconstructed'})
grid on
title('Original and Reconstructed Signal')

linkaxes(ax, 'xy')
