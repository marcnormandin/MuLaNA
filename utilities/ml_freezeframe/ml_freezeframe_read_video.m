function [videoFrames] = ml_freezeframe_read_video(fn)
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

        %frame = fread(fileId, frameSize, 'uint8', 'ieee-be');
        frame = fread(fileId, frameSize, 'uint8');
        if isempty(frame)
            break;
        end

        % This hasn't been tested with non-square videos so if the video
        % looks odd then change the order of width and height.
        block = reshape(frame, height, width);
        block = block';
        
        frame = decode_frame(block, width, height);

        framesRead = framesRead + 1;

        if feof(fileId)
            break;
        end

        videoFrames(framesRead).width = width;
        videoFrames(framesRead).height = height;
        videoFrames(framesRead).frame = frame;
    end
    fclose(fileId);
end % function

function [frame] = decode_frame(b0, frameWidth, frameHeight)
    % No idea why the frame has to be stitched together like this, but it works
    
    % 320x240 meant I had to use a value of 80 = 240 / 3
    % No idea what FreezeFrame does for other dimensions
    m = 3;
    n = frameHeight / m;
    b = [];
    b{1} = b0(:,1:n);
    b{2} = b0(:, (n+1):(2*n));
    b{3} = b0(:,(2*n+1):end);

    
    c = zeros(frameWidth*m,n); % the 80 will likely change if a frame dimension changes.
    k = 1;
    for i = 1:frameWidth
        for j = 1:m
            d = b{j};
            c(k,:) = d(i,:);
            k = k + 1;
        end

    end

    % Stick the 4 columns together
    c1 = c(1:4:end,:);
    c2 = c(2:4:end,:);
    c3 = c(3:4:end,:);
    c4 = c(4:4:end,:);

    frame = horzcat(c1, c2, c3, c4);
    frame = uint8(flipud(frame));
end % function