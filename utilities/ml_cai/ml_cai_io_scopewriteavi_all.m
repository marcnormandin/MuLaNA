function ml_cai_io_scopewriteavi_all( framesToWrite, outputFolder, filenamePrefix, filenameSuffix )

    numFramesPerVideo = 1000;

    numFramesToWrite = size(framesToWrite, 3);
    
    if numFramesToWrite < 1
        error('No frames to write.');
    else
        fprintf('Writing %d frames to file.\n', numFramesToWrite);
    end

    videoNum = 0;
    v = [];
    for frameNum = 1:numFramesToWrite
        if mod(frameNum, numFramesPerVideo) == 1
            videoNum = videoNum + 1;
            filename = fullfile( outputFolder, [filenamePrefix num2str(videoNum) filenameSuffix] );
            if ~isempty(v)
                close(v);
            end
            v = VideoWriter( filename, 'Grayscale AVI' );
            v.FrameRate = 20; % Needed because of function read_file which assumes that it is 20
            open(v);
            fprintf('Writing scope video to %s\n', filename);
        end
        writeVideo( v, uint8( framesToWrite(:,:,frameNum) ) );
    end
    close(v);

end % function
