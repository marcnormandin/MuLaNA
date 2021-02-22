    function data = ml_cai_io_timestampdat_readfile ( timestampFilename )
        data = [];
        
        if ~isfile( timestampFilename )
            error('The file (%s) does not exist.', timestampFilename);
        end

        fid = fopen( timestampFilename );
        if fid == -1
            error(fprintf('Unable to open the timestamp file (%s).\n', timestampFilename))
        end

        % read the header to skip it
        headerLine = fgets(fid); % dummy read

        rows = textscan(fid,'%f\t%f\t%f\t%f');
        data.cameraNum = rows{1};
        data.frameNum = rows{2};
        data.sysClock = rows{3}; % ms
        data.bufferNum = rows{4};

%         % The first sysClock value for each camera is junk, so set it to (near) zero
%         % Don't first frame of all cameras to zero because it will mess
%         % with finding duplicate timestamps
%         cameraIds = data.CameraIds();
%         for iCamera = 1:data.NumCameras()
%             data.sysClock( data.cameraNum == cameraIds(iCamera) & data.frameNum == 1 ) = iCamera; 
%         end

        fclose(fid);
    end % function
        