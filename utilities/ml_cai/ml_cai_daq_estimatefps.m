function [estFps, percentFps] = ml_cai_daq_estimatefps( timestamp_ms )
% timestamp_ms should be an array of timestamps in milliseconds

% The fps to check (these are the default DAQ options)
FPS_TO_CHECK = [5 10 15 20 30 60];
% +/- DFPS
DFPS = 5;

% Compute the instantaneous fps across time
fps = 1 ./ double(diff(timestamp_ms)) * 1000.0;

fpsCounts = zeros(1, length(FPS_TO_CHECK));
for i = 1:length(FPS_TO_CHECK)
   fpsCounts(i) = sum( (fps > FPS_TO_CHECK(i) - DFPS) & (fps < FPS_TO_CHECK(i) + DFPS) );
end

[countsOfMax, indexOfMax] = max( fpsCounts );

% The estimated FPS that the experimenter used
estFps = FPS_TO_CHECK( indexOfMax );
percentFps = countsOfMax / (length(timestamp_ms) - 1) * 100;

end % function
