%% Concatenate all the videos of the trials into one data set that spans the entire session.
function ml_miniscope_pipeline_concatenated_make_scopevideos(session)

    numTrials = session.getNumTrials();

    %fprintf('Processing session %d of %d (%s)\n', iSession, numSessions, session.getName());
    
    sessionDirectorySep = session.getSessionDirectory();
    sessionDirectoryCat = strrep(sessionDirectorySep, '_sep', '_cat');
    destVideoFolder = fullfile(sessionDirectoryCat, 'H1_M1_S1'); % We will create a single trial
    

    filenamePrefix = 'msCam';
    filenameSuffix = '.avi';

    numFramesPerVideoMax = 1000;
    currentVideoNum = 1;
    combinedFrames = [];
    for iTrial = 1:numTrials
        trial = session.getTrial(iTrial);
        videoFolder = trial.getTrialDirectory();

        videoFilenames = dir(fullfile(videoFolder, sprintf('%s*%s', filenamePrefix, filenameSuffix)));
        numVideos = length(videoFilenames);

        for iVideo = 1:numVideos
            videoToRead = fullfile(videoFilenames(iVideo).folder, [filenamePrefix num2str(iVideo) filenameSuffix]);
            fprintf('Processing Trial %d of %d, video %d of %d: %s\n', iTrial, numTrials, iVideo, numVideos, videoToRead);
            video = ml_cai_io_scopereadavi(videoToRead);

            numFrames = video.numFrames;

            frames = zeros(video.height, video.width, numFrames);
            for iFrame = 1:numFrames
                frames(:,:,iFrame) = video.mov(iFrame).cdata;
            end

            if isempty(frames)
               combinedFrames = frames; 
            else
               %combinedFrames = [combinedFrames, frames];
               combinedFrames = cat(3, combinedFrames, frames);
            end
            
            fprintf('%d frames in buffer\n', size(combinedFrames,3));
        
            % Save any full videos that we can
            numSavedFrames = size(combinedFrames,3);
            while numSavedFrames >= numFramesPerVideoMax
                fprintf('%d frames in buffer\n', size(combinedFrames,3));

                framesToSave = combinedFrames(:,:,1:numFramesPerVideoMax);
                numFramesToWrite = size(framesToSave,3);

                combinedFrames(:,:,1:numFramesPerVideoMax) = [];
                numSavedFrames = size(combinedFrames,3);

                vidFilename = fullfile( destVideoFolder, [filenamePrefix num2str(currentVideoNum) filenameSuffix] );
                fprintf('Writing %d frames to scope video to %s\n', numFramesToWrite, vidFilename);

                % Create a new video
                v = VideoWriter( vidFilename, 'Grayscale AVI' );
                v.FrameRate = 20; % Needed because of function read_file which assumes that it is 20
                open(v);    
                for frameNum = 1:numFramesToWrite
                    writeVideo( v, uint8( framesToSave(:,:,frameNum) ) );
                end
                close(v)

                currentVideoNum = currentVideoNum + 1;
            end
        end % iVideo
    end % iTrial

    % Save whatever partial video file is left
    numSavedFrames = size(combinedFrames,3);
    if numSavedFrames ~= 0
        fprintf('Final stage: %d frames in buffer\n', size(combinedFrames,3));

        framesToSave = combinedFrames;
        numFramesToWrite = size(framesToSave,3);
        
        vidFilename = fullfile( destVideoFolder, [filenamePrefix num2str(currentVideoNum) filenameSuffix] );
        fprintf('Writing %d frames to scope video to %s\n', numFramesToWrite, vidFilename);
        
        v = VideoWriter( vidFilename, 'Grayscale AVI' );
        v.FrameRate = 20; % Needed because of function read_file which assumes that it is 20
        open(v);
        for frameNum = 1:numFramesToWrite
            writeVideo( v, uint8( framesToSave(:,:,frameNum) ) );
        end
        close(v);

        currentVideoNum = currentVideoNum + 1;
    end
end

