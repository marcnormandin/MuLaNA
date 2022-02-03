function [notched] = ml_util_filter_powerline_noise(eeg, fs)
    %fs = 400; % Sampling frequency of the EEG
    % Notch filter for the 60 Hz line frequency
    d = designfilt('bandstopiir','FilterOrder',4, ...
                   'HalfPowerFrequency1',59,'HalfPowerFrequency2',61, ...
                   'DesignMethod','butter','SampleRate',fs);
    notched = filtfilt(d, eeg);
end