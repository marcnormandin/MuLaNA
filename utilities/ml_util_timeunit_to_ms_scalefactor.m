function [timeScaleFactor] = ml_util_timeunit_to_ms_scalefactor( timeUnits )
    switch timeUnits
        case 'seconds'
            timeScaleFactor = 10^3;
        case 'milliseconds'
            timeScaleFactor = 1;
        case 'microseconds'
            timeScaleFactor = 10^(-3);
        otherwise
            error('Unsupported time conversion unit');
    end
end % function
