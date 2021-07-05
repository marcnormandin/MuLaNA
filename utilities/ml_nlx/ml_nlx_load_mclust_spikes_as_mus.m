function spikeTimes_mus = ml_nlx_load_mclust_spikes_as_mus(nlxNvtTimeStamps_mus, tFilename, numBits)
    isVerbose = false; % Set to true for debugging.
    
    if numBits == 32
        spikeTimes_mclust = ml_nlx_mclust_load_spikes_32bit(tFilename);
        spikeTimes_mus = spikeTimes_mclust .* 10^6;

    elseif numBits == 64
        spikeTimes_mclust = ml_nlx_mclust_load_spikes_64bit(tFilename);
        spikeTimes_mus = spikeTimes_mclust .* 10^6;
        
    elseif numBits == -1
        % Load it as 32 bit
        spikeTimes_mclust = ml_nlx_mclust_load_spikes_32bit(tFilename);
        spikeTimes_mus_32bit = spikeTimes_mclust .* 10^6;
        is32BitValid = ml_nlx_mclust_spiketimes_are_valid(nlxNvtTimeStamps_mus, spikeTimes_mus_32bit, isVerbose);

        % Load it as 64 bit
        spikeTimes_mclust = ml_nlx_mclust_load_spikes_64bit(tFilename);
        spikeTimes_mus_64bit = spikeTimes_mclust .* 10^6;
        is64BitValid = ml_nlx_mclust_spiketimes_are_valid(nlxNvtTimeStamps_mus, spikeTimes_mus_64bit, isVerbose);
        
        if is32BitValid && ~is64BitValid
            spikeTimes_mus = spikeTimes_mus_32bit;
        elseif ~is32BitValid && is64BitValid
            spikeTimes_mus = spikeTimes_mus_64bit;
        elseif ~is32BitValid && ~is64BitValid
            error('The tfile ( %s ) is not valid for 32 bits or 64 bits!\n', tFilename);
        else
            error('The tfile ( %s ) is valid for both 32 bits and 64 bits indicating a problem with the data or its loading.\n', tFilename);
        end
    else
        error('numBits must be 32 or 64 (or -1 for automatic determination)');
    end
end
