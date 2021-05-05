function [dateTag] = ml_util_gen_datetag()
    dateTag = datestr(now, 'yyyymmdd_HHMMSS');
end
