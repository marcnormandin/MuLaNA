function [traceMap] = ml_cai_placefield_tracemap(sxi, syi, nonuniformTrace, nbinsx, nbinsy)
    % Perform the counts by hand because I don't trust MATLAB
    numi = length(sxi);
    traceMap = zeros(nbinsy, nbinsx);
    for i = 1:numi
        prevCount = traceMap( syi(i), sxi(i) );
        traceMap( syi(i), sxi(i) ) = prevCount + nonuniformTrace(i);
    end
end
