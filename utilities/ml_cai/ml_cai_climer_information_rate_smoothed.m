function [climerICS] = ml_cai_climer_information_rate_smoothed(probXYS, traceXYS)
    meanTraceS = nansum(probXYS .* traceXYS, 'all');
    climerICS = nansum( traceXYS .* probXYS .* log2( traceXYS ./ meanTraceS ), 'all' );
end