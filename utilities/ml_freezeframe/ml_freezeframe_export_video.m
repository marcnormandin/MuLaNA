function [exportedFilename] = ml_freezeframe_export_video(freezeframeFilename, frameRate_hz, exportFolder)
    %frameRate_hz = 15;

    [filepath, name, ext] = fileparts(freezeframeFilename);
    if ~strcmp(ext, '.ffii')
        error('Can only read FreezeFrame video that end in ".ffii".\n');
    end
    
    if ~isfile(freezeframeFilename)
        error('The file (%s) can not be exported as it does not exist.\n', freezeframeFilename);
    end
    
    exportedFilename = fullfile(exportFolder, sprintf('%s.avi', name));

    % Read in the limelight video data
    videoFrames = ml_freezeframe_read_video(freezeframeFilename);
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
end % function
