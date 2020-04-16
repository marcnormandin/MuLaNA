function spikeTimes = ml_nlx_mclust_load_spikes_32bit(filename)
    % Load t-files as 32 bits
    
    fid = fopen(filename, 'rb','b');
    if (fid == -1)
        error('Could not open t-file %s.', filename);
    end

    ml_mclust_readheader(fid);

    spikeTimes = fread(fid,inf,'uint32');           

    fclose(fid);		

    % unit conversion
    spikeTimes = spikeTimes ./ 10000;
end
