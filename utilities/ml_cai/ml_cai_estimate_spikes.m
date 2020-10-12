function [spike_times_ms] = ml_cai_estimate_spikes(timestamps_ms, trace_raw)

    mstd = movstd(trace_raw, 7);
    x = linspace(0, max(mstd), 1000);
    mmstd = mstd; % lognfit can't use values of 0
    mmstd(mmstd <= 0) = [];
    
    pt = prctile(x, 75);
    mmstd(mmstd >= pt) = [];
    
    pHat = lognfit(mmstd);

    p = 1 - logncdf(mstd, pHat(1), pHat(2));
    ci = find(p <= 0.01);
    
    % reduce to only those that are consecutive and the trace is increasing
    cci = [];
    for i = 1:length(ci)-2
        % Must be 3 consecutive
        if ci(i+2)-1 == ci(i+1) && ci(i+1)-1 == ci(i)
            % Must all be increasing
            if trace_raw(ci(i+2)) >= trace_raw(ci(i+1)) && trace_raw(ci(i+1)) >= trace_raw(ci(i)) && trace_raw(ci(i)) > 0
                cci = [cci, ci(i)];
            end
        end
    end
    
    if ~isempty(cci)
        spike_times_ms = timestamps_ms(cci);
    else
        spike_times_ms = [];
    end
end

function [spike_times_ms] = ml_cai_estimate_spikes_using_mlspike(timestamps_ms, trace_raw)
    dt_s = median( diff(timestamps_ms/1000.0), 'all' );
    
    par = tps_mlspikes('par');
    % (indicate the frame duration of the data)
    par.dt = dt_s;
    % (set physiological parameters)
    par.a = 10; %0.5; %default 0.07 % DF/F for one spike
    par.tau = 1; % default 1 % decay time constant (second)
    par.saturation = 0; %0.000002; % OGB dye saturation
    % (set noise parameters)
    par.finetune.sigma = []; % default .02; % a priori level of noise (if par.finetune.sigma
                              % is left empty, MLspike has a low-level routine 
                              % to try estimating it from the data
    %par.drift.parameter = []; %0.01; % default .01; % if par.drift parameter is not set, the 
                               % algorithm assumes that the baseline remains
                               % flat; it is also possible to tell the
                               % algorithm the value of the baseline by setting
                               % par.F0
    %par.F0 = 0;
    % (do not display graph summary)
    par.dographsummary = true;

    % spike estimation
    [spikest fit drift] = spk_est({trace_raw},par);
    spike_times_ms = spikest{1} * 1000; % convert from seconds to milliseconds
end
