function [timeScaleFactor] = ml_util_timeunit_to_s_scalefactor( timeUnits )
    switch timeUnits
        case 'seconds'
            timeScaleFactor = 1;
        case 'milliseconds'
            timeScaleFactor = 10^3;
        case 'microseconds'
            timeScaleFactor = 10^(6);
        otherwise
            error('Unsupported time conversion unit');
    end
end % function
