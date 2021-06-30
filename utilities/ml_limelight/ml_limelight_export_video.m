function [exportedFilename] = ml_limelight_export_video(limelightFilename, frameRate_hz)
    %frameRate_hz = 15;

    [filepath, name, ext] = fileparts(limelightFilename);
    if ~strcmp(ext, '.llii')
        error('Can only read FreezeFrame video that end in ".llii".\n');
    end
    
    if ~isfile(limelightFilename)
        error('The file (%s) can not be exported as it does not exist.\n', limelightFilename);
    end
    
    exportedFilename = fullfile(filepath, sprintf('%s.avi', name));

    % Read in the limelight video data
    videoFrames = ml_limelight_read_video(limelightFilename);
    numFrames = length(videoFrames);

    % Export the video to the MP4 format
    %v = VideoWriter( exportedFilename, 'MPEG-4' );
    v = VideoWriter( exportedFilename, 'Motion JPEG AVI');
    v.FrameRate = frameRate_hz;
    open(v);
    for iFrame = 1:numFrames
        frame = videoFrames(iFrame).frame;
        writeVideo( v, frame );
    end
    close(v);
end

