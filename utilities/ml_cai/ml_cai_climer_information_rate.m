function [climerICS] = ml_cai_climer_information_rate(bs, probXYS, smoothingKernelXY, trace_x_valid, trace_y_valid, trace_value_valid)
    traceXY = ml_bs_accumulate_xy(bs, trace_x_valid, trace_y_valid, trace_value_valid);
    traceXYS = imfilter(traceXY, smoothingKernelXY);
    meanTraceS = nansum(probXYS .* traceXYS, 'all');
    climerICS = nansum( traceXYS .* probXYS .* log2( traceXYS ./ meanTraceS ), 'all' );
end