function [videoFrames] = ml_limelight_read_video(fn)
    % This function read a limelight video file ("llii" extension).
    
    if isempty(fn)
        error('Filename is empty');
    end

    if ~isfile(fn)
        error('The file does not exist (%s)\n', fn);
    end

    fileId = fopen(fn);
    if fileId == -1
        error('Unable to open the file for reading: %s\n', fn);
    end

    videoFrames = [];
    framesRead = 0;
    while 1
        
        height = fread(fileId, 1, 'uint32', 'ieee-be');
        if isempty(height)
            break;
        end
        
        width = fread(fileId, 1, 'uint32', 'ieee-be');
        if isempty(width)
            break;
        end



        frameSize = width*height;

        frame = fread(fileId, frameSize, 'uint8', 'ieee-be');
        if isempty(frame)
            break;
        end

        % This hasn't been tested with non-square videos so if the video
        % looks odd then change the order of width and height.
        frame = reshape(frame, width, height);
        
        frame = frame';

        framesRead = framesRead + 1;

        if feof(fileId)
            break;
        end

        videoFrames(framesRead).width = width;
        videoFrames(framesRead).height = height;
        videoFrames(framesRead).frame = uint8(frame);
    end
    fclose(fileId);
end % function