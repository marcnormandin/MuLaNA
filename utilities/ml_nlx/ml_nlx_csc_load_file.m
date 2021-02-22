function [ts_mus, csc, channel, fs] = ml_nlx_csc_load_file( cscFilename )

    [Timestamps_mus, ChannelNumbers, SampleFrequencies,NumberOfValidSamples, Samples, Header] = ...
        Nlx2MatCSC(cscFilename,[1 1 1 1 1], 1, 1, [] );

    % Make an array of sample times since Neuralynx Timestamps_mus are only
    % 1 per 512 samples.
    nr = size(Samples,1);
    nc = size(Samples,2);
    ts_mus = nan(1, nr * nc);
    for m = 1:nc
       fs_hz = SampleFrequencies(m);
       fs_cycles_per_mus = fs_hz / 10^6;
       for n = 1:nr
           ts_mus( (m-1)*nr + n ) = Timestamps_mus(m) + (n-1)/fs_cycles_per_mus;
       end
    end

    csc = reshape(Samples, 1, nc*nr);

    channel = unique(ChannelNumbers);
    if length(channel) ~= 1
        error('CSC has more than one channel!');
    end
    
    fs = median(SampleFrequencies);
end % function
