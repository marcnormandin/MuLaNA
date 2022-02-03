function [timeScaleFactor] = ml_util_timeunit_conversion_scalefactor( timeUnitsFrom, timeUnitsTo )
    % A to s
    f1 = convert_to_seconds( timeUnitsFrom );
    f2 = convert_to_seconds( timeUnitsTo );
    timeScaleFactor = f1 / f2;
end % function

function [ timeScaleFactor ] = convert_to_seconds( timeUnits )
    switch timeUnits
        case 'seconds'
            timeScaleFactor = 1;
        case 'milliseconds'
            timeScaleFactor = 10^(-3);
        case 'microseconds'
            timeScaleFactor = 10^(-6);
        otherwise
            error('Unsupported time conversion unit');
    end
end
