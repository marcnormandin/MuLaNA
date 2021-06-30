function ml_sim_mclust_tfile_write(spikeTimestamps_ms, tfileBits, outputTFullFilename)
   % This function saves spiketimes to a MClust t-file, but I changed
   % some of the header information since this is to be used with simulated
   % data and we don't want to lose track of that in the future.
   
   spikeTimes_s = spikeTimestamps_ms / 1000;
   spikeTimes_mus = spikeTimes_s * 10^6; % convert from seconds to microseconds

    % Open the file
    if isfile(outputTFullFilename)
        delete(outputTFullFilename);
    end
    fp = fopen(outputTFullFilename, 'wb', 'b');
    if (fp == -1)
     error(['Could not open file"' fn '".']);
    end
    
    % Save the header
    header = ml_sim_mclust_tfile_header(tfileBits);
    for iH = 1:length(header)
       fwrite(fp, sprintf('%s\n', header{iH}));
    end

    % Save the spikes
    if tfileBits == 32
        fwrite(fp, round(spikeTimes_mus ./ 100), 'uint32');
    elseif tfileBits == 64
        fwrite(fp, round(spikeTimes_mus ./ 100), 'uint64');
    else
        error('Invalid tfileBits (%d)\n', tfileBits);
    end
    
    % All done
    fclose(fp);
end % function