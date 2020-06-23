function [p] = ml_cai_behavcam_referenceframe_create( trialFolder, dataFolder, varargin )
    p = inputParser;
    p.CaseSensitive = false;
    
    addRequired(p,'trialFolder', @isstr);
    addRequired(p,'dataFolder', @isstr);
    
    addParameter(p, 'outputFolder', dataFolder, @isstr);
    addParameter(p, 'verbose', false, @islogical);
    addParameter(p, 'behavRecordFilename', 'behav.hdf5', @isstr);
    addParameter(p, 'maxFramesToUse', 5000, @isscalar);
    addParameter(p, 'backgroundFrameFilenamePrefix', 'behavcam_background_frame', @isstr);
    
    parse(p, trialFolder, dataFolder, varargin{:});
    
    if p.Results.verbose
        fprintf('Using the following settings:\n');
        disp(p.Results)
    end
    
    fn = fullfile(dataFolder, p.Results.behavRecordFilename);
    if p.Results.verbose
        fprintf('Reading behaviour record from %s ... ', fn);
    end
    mlvidrec = MLVideoRecord( fn );
    if p.Results.verbose
        fprintf('done!\n');
    end
    
    % No video is loaded at the start
    videoNumLoaded = -1;
    globalFrameNum = 1;
    video = [];
    
    if p.Results.verbose
        fprintf('Reading behaviour frames to compute the background.\n');
    end
    
    while true
        videoNumNeeded = mlvidrec.videoNum( globalFrameNum );
        if videoNumLoaded ~= videoNumNeeded
            videoFilename = fullfile(trialFolder, sprintf('%s%d%s', mlvidrec.videoFilenamePrefix, videoNumNeeded, mlvidrec.videoFilenameSuffix));
            
            if p.Results.verbose
                fprintf('Loading %s ... ', videoFilename);
            end
            
            videoFrames = ml_cai_io_behavreadavi(videoFilename);
            
            if p.Results.verbose
                fprintf('done!\n');
            end
            
            videoNumLoaded = videoNumNeeded;

            numLocalFrames = length(videoFrames.mov);                    

            if isempty(video)
                video = videoFrames;
            else
                video.mov(end+1:end+numLocalFrames) = videoFrames.mov;
                video.numFrames = video.numFrames + numLocalFrames;
            end
            
            % Process all of the frames (which are local to the video file
            % loaded).
            globalFrameNum = globalFrameNum + numLocalFrames;
        end

        if globalFrameNum >= mlvidrec.numFrames || globalFrameNum >= p.Results.maxFramesToUse
            break
        end
    end
    
    % Alert the user if less than the chosen number of frames was used
    % due to too short of a video record
    if globalFrameNum < p.Results.maxFramesToUse
        fprintf('Warning! Only %d frames were used (instead of requested %d) due to not enough frames.\n', globalFrameNum, p.Results.maxFramesToUse);
    end
    
    if p.Results.verbose
        fprintf('All frames read. Now computing the median frame to be used as the background (takes a long time!).\n');
    end
    
    behavcam_background_frame = ml_cai_behavcam_median_frame_compute(video);

    % Save background as a png
    fn = fullfile(p.Results.outputFolder, [p.Results.backgroundFrameFilenamePrefix '.png']);
    if p.Results.verbose
        fprintf('Saving file to %s\n', fn);
    end
    imwrite( behavcam_background_frame, fn );
    
    % Save background as a mat file.
    fn = fullfile(p.Results.outputFolder, [p.Results.backgroundFrameFilenamePrefix '.mat']);
    if p.Results.verbose
        fprintf('Saving file to %s\n', fn);
    end
    save( fn, 'behavcam_background_frame' );

    % Save background as a figure
    h = figure;
    imshow(behavcam_background_frame)
    fn = fullfile(p.Results.outputFolder, [p.Results.backgroundFrameFilenamePrefix '.fig']);
    if p.Results.verbose
        fprintf('Saving file to %s\n', fn);
    end
    savefig( h, fn, 'compact' );
    close(h);
end % function
