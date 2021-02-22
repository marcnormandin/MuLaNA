function [rand_shift_ms, rand_shift_n] = ml_util_rand_timeshift(ts_ms, shiftMin_ms, numDraws)
%             tshift_min = ts_ms(1) + shiftMin_ms; % min seconds from start
%             tshift_max = ts_ms(end) - shiftMin_ms; % min seconds before end
%             tshift_draw_ms = (tshift_max - tshift_min).*rand(1,numDraws) + tshift_min; % shift as a time value
%             tshift_draw_n = round(tshift_draw_ms ./ median(diff(ts_ms), 'all')); % shift as an array shift value

    duration_ms = ts_ms(end) - ts_ms(1);
    max_shift_ms = duration_ms - 2*shiftMin_ms;
    rand_shift_ms = max_shift_ms*rand(1,numDraws) + shiftMin_ms;
    rand_shift_n = round(rand_shift_ms ./ median(diff(ts_ms), 'all'));
end
