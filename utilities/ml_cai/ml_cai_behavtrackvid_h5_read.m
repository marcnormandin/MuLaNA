function [position] = ml_cai_behavtrackvid_h5_read( filename )

if ~isfile(filename)
    error("Cannot read from (%s) as it does not exist.", filename);
end

pi = h5read( filename, '/pos_vid_pixel_i');
pj = h5read( filename, '/pos_vid_pixel_j');

position.x = pi;
position.y = pj;
position.timestamps_ms = double(h5read( filename, '/timestamp_ms' ));

end % function
