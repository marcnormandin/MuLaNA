function [header] = ml_nlx_mclust_load_spikes_header(filename)
    fid = fopen(filename, 'rb','b');
    if (fid == -1)
        error('Could not open t-file %s.', filename);
    end

    header = ml_mclust_readheader(fid);
    
    fclose(fid);
end