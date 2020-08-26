function [status, p] = ml_cai_daq_camerasdat_create( dataFolder, varargin )
    p = inputParser;
    p.CaseSensitive = false;
    
    addRequired(p,'dataFolder', @isstr);
    addParameter(p,'timestampFilename', 'timestamp.dat', @isstr);
    addParameter(p,'notesFilename', 'settings_and_notes.dat', @isstr);
    addParameter(p,'maxFramesPerVideo', 1000, @isscalar);
    addParameter(p,'scopeVideoFilenamePrefix', 'msCam', @isstr);
    addParameter(p,'scopeVideoFilenameSuffix', '.avi', @isstr);
    addParameter(p,'behavVideoFilenamePrefix', 'behavCam', @isstr);
    addParameter(p,'behavVideoFilenameSuffix', '.avi', @isstr);
    addParameter(p,'outputScopeDatFilename', 'scope.dat', @isstr);
    addParameter(p,'outputBehavDatFilename', 'behav.dat', @isstr);
    addParameter(p,'outputFolder', dataFolder, @isstr);
    addParameter(p,'verbose', false, @islogical);
    
    addParameter(p,'scopeCameraId', 1, @isscalar);
    addParameter(p,'behavCameraId', 0, @isscalar);
    addParameter(p,'interactive', false, @islogical);
    addParameter(p,'hasBehaviour', true, @islogical);
    
    parse(p, dataFolder, varargin{:});
    

    
    DAQ_TIMESTAMP_FILENAME = p.Results.timestampFilename;
    DAQ_NOTES_FILENAME = p.Results.notesFilename;
    

    DAQ_MAX_FRAMES_PER_VIDEO = p.Results.maxFramesPerVideo;

    DAQ_SCOPE_VIDEO_FILENAME_PREFIX = p.Results.scopeVideoFilenamePrefix;
    DAQ_SCOPE_VIDEO_FILENAME_SUFFIX = p.Results.scopeVideoFilenameSuffix;
    DAQ_BEHAV_VIDEO_FILENAME_PREFIX = p.Results.behavVideoFilenamePrefix;
    DAQ_BEHAV_VIDEO_FILENAME_SUFFIX = p.Results.behavVideoFilenameSuffix;

    ML_SCOPE_DAT_FILENAME = p.Results.outputScopeDatFilename;
    ML_BEHAV_DAT_FILENAME = p.Results.outputBehavDatFilename;

    OUTPUT_FOLDER = p.Results.outputFolder;
    VERBOSE = p.Results.verbose;
    INTERACTIVE = p.Results.interactive;
    
    if VERBOSE
        fprintf('Using the following settings:\n');
        disp(p.Results)
    end
    
    % Create the output folder if it doesn't already exist
    if ~isfolder(p.Results.outputFolder)
        if VERBOSE
            fprintf('Creating output folder (%s) ... ', p.Results.outputFolder);
        end
        mkdir(p.Results.outputFolder);
        if VERBOSE
            fprintf('done!\n');
        end
    end
    
    fn = fullfile(dataFolder, DAQ_TIMESTAMP_FILENAME);
    
        % Read 'timestamp.dat'
        daqts = DAQTimeStamp(fn);
        
        % Read 'settings_and_notes.dat'
        san = DAQSettingsAndNotes(fullfile(dataFolder, DAQ_NOTES_FILENAME));
        
        % Get a list and count of all of the scope videos
        scopeFiles = dir(fullfile(dataFolder, [DAQ_SCOPE_VIDEO_FILENAME_PREFIX '*' DAQ_SCOPE_VIDEO_FILENAME_SUFFIX]));
        numScopeFiles = length(scopeFiles);
        hasScope = true;
        if numScopeFiles == 0
            hasScope = false;
        end
        
        numScopeFrames = 0;
        scopeVideoWidth = 0;
        scopeVideoHeight = 0;
        if hasScope
            numScopeFrames = (numScopeFiles - 1) * DAQ_MAX_FRAMES_PER_VIDEO;
            % We need to add in the last file which probably has less than the
            % maximum number of frames.
            lastScopeVideo = ml_cai_io_scopereadavi( fullfile(dataFolder, [DAQ_SCOPE_VIDEO_FILENAME_PREFIX num2str(numScopeFiles) DAQ_SCOPE_VIDEO_FILENAME_SUFFIX]) );
            numScopeFrames = numScopeFrames + lastScopeVideo.numFrames;
            scopeVideoWidth = lastScopeVideo.width;
            scopeVideoHeight = lastScopeVideo.height;

            if VERBOSE
                fprintf('Scope frames = %d x %d x %d\n', scopeVideoWidth, scopeVideoHeight, numScopeFrames);
            end
        end
        
        % Check if, in addition to the miniscope, a behaviour camera was
        % used. We assume if more than one camera, then at least one
        % behaviour camera was used.
        %hasBehaviourCamera = daqts.NumCameras() > 1;
        behavFiles = dir(fullfile(dataFolder, [DAQ_BEHAV_VIDEO_FILENAME_PREFIX '*' DAQ_BEHAV_VIDEO_FILENAME_SUFFIX]));
        numBehavFiles = length(behavFiles);
        hasBehaviourCamera = true;
        if numBehavFiles == 0
            hasBehaviourCamera = false;
        end
        
        numBehavFrames = 0;
        behavVideoWidth = 0;
        behavVideoHeight = 0;
        if hasBehaviourCamera 
            numBehavFrames = (numBehavFiles - 1) * DAQ_MAX_FRAMES_PER_VIDEO;
            behavFrames = ml_cai_io_behavreadavi( fullfile(dataFolder, [DAQ_BEHAV_VIDEO_FILENAME_PREFIX num2str(numBehavFiles) DAQ_BEHAV_VIDEO_FILENAME_SUFFIX]) );
            numBehavFrames = numBehavFrames + behavFrames.numFrames;
            behavVideoWidth = behavFrames.width;
            behavVideoHeight = behavFrames.height;
        end
        
        if VERBOSE
            fprintf('Behav frames = %d x %d x %d\n', behavVideoWidth, behavVideoHeight, numBehavFrames);
        end
        
        % Estimate the FPS that was used
        estFps = zeros(1, daqts.NumCameras());
        estFpsPercent = zeros(1, daqts.NumCameras());
        camIds = daqts.CameraIds();
        for iCam = 1:daqts.NumCameras()
            camts(iCam) = daqts.CameraSubset( camIds(iCam) );
            [efps, efpsp] = ml_cai_daq_estimatefps( double(camts(iCam).sysClock) );
            estFps(iCam) = efps;
            estFpsPercent(iCam) = efpsp;
        end
        
        % Now try to find the proper mapping between the camera ids
        % and the video sets
        
        if hasScope && hasBehaviourCamera
            keySet = {'behav', 'scope'};
            valueSet = [[], []];
        elseif hasScope
            keySet = {'scope'};
            valueSet = [[]];
        elseif hasBehaviourCamera
            keySet = {'behav'};
            valueSet = [[]];
        else
            error('No scope or behaviour camera videos are present.')
        end

        if numBehavFrames == numScopeFrames
            if VERBOSE
                fprintf('Both behav and scope cameras have the same number of frames! Unable to determine camera IDs automatically! Enter manually!\n');
            end
            
            if INTERACTIVE
                answer = [];
                while isempty(answer)
                    prompt = {'Enter behaviour camera ID', 'Enter miniscope camera ID'};
                    dlgtitle = 'Unable to determine the camera IDs automatically. Enter manually';
                    dims = [1 100];
                    definput = {'0', '1'};
                    answer = inputdlg(prompt, dlgtitle, dims, definput);
                end
                behavId = str2double(answer{1});
                scopeId = str2double(answer{2});
                valueSet = [behavId, scopeId];
            else
                fprintf('Warning. Both the behaviour camera and the miniscope videos have the same number of frames so the camera ids can not be resolved automatically. Assigning default ids.');
                %status = -1;
                behavId = 0;
                scopeId = 1;
                valueSet = [behavId, scopeId];
            end
        else
            % Determine it automatically based on the frame count
            for i = 1:daqts.NumCameras()
                if length(camts(i).sysClock) == numBehavFrames
                    valueSet(1) = camts(i).cameraNum(1);
                end

                if length(camts(i).sysClock) == numScopeFrames
                    valueSet(2) = camts(i).cameraNum(1);
                end
            end
        end
    
        camMap = containers.Map(keySet, valueSet);
        
        if VERBOSE
            fprintf('%s: %s\n', fn, san.animal);
        end
        %for iCam = 1:length(estFps)
        %    fprintf('%d: %d (%0.2f)\n', camIds(iCam), estFps(iCam), estFpsPercent(iCam));
        %end
        
        % scope should always be present
        if hasScope
            scopeId = camMap('scope');
            ind = find( camIds == scopeId );

            if VERBOSE
                fprintf('scope (%d): %d x %d x %d @ (%d, %0.2f) %s %s %d %d\n', scopeId, scopeVideoWidth, scopeVideoHeight, numScopeFrames, estFps(ind), estFpsPercent(ind), ...
                    DAQ_SCOPE_VIDEO_FILENAME_PREFIX, DAQ_SCOPE_VIDEO_FILENAME_SUFFIX, numScopeFiles, DAQ_MAX_FRAMES_PER_VIDEO);
            end

            scopeDat = DAQCamera;
            scopeDat.cameraId = scopeId;
            scopeDat.numFrames = numScopeFrames;
            scopeDat.maxFramesPerVideo = DAQ_MAX_FRAMES_PER_VIDEO;
            scopeDat.numVideos = numScopeFiles;
            scopeDat.estFps = estFps(ind);
            scopeDat.estFpsPercent = estFpsPercent(ind);
            scopeDat.videoWidth = scopeVideoWidth;
            scopeDat.videoHeight = scopeVideoHeight;
            scopeDat.videoFilenamePrefix = DAQ_SCOPE_VIDEO_FILENAME_PREFIX;
            scopeDat.videoFilenameSuffix = DAQ_SCOPE_VIDEO_FILENAME_SUFFIX;
            scopeDat.savefile( fullfile(OUTPUT_FOLDER, ML_SCOPE_DAT_FILENAME) );
            if VERBOSE
                fprintf('Data saved to %s\n', fullfile(OUTPUT_FOLDER, ML_SCOPE_DAT_FILENAME));
            end
        end
        
        % behav
        if hasBehaviourCamera
            behavId = camMap('behav');
            ind = find( camIds == behavId );

            if VERBOSE
                fprintf('behav (%d): %d x %d x %d @ (%d, %0.2f) %s %s %d %d\n', behavId, behavVideoWidth, behavVideoHeight, numBehavFrames, estFps(ind), estFpsPercent(ind), ...
                    DAQ_BEHAV_VIDEO_FILENAME_PREFIX, DAQ_BEHAV_VIDEO_FILENAME_SUFFIX, numBehavFiles, DAQ_MAX_FRAMES_PER_VIDEO);
            end

            behavDat = DAQCamera;
            behavDat.cameraId = behavId;
            behavDat.numFrames = numBehavFrames;
            behavDat.maxFramesPerVideo = DAQ_MAX_FRAMES_PER_VIDEO;
            behavDat.numVideos = numBehavFiles;
            behavDat.estFps = estFps(ind);
            behavDat.estFpsPercent = estFpsPercent(ind);
            behavDat.videoWidth = behavVideoWidth;
            behavDat.videoHeight = behavVideoHeight;
            behavDat.videoFilenamePrefix = DAQ_BEHAV_VIDEO_FILENAME_PREFIX;
            behavDat.videoFilenameSuffix = DAQ_BEHAV_VIDEO_FILENAME_SUFFIX;
            behavDat.savefile( fullfile(OUTPUT_FOLDER, ML_BEHAV_DAT_FILENAME) );
            if VERBOSE
                fprintf('Data saved to %s\n', fullfile(OUTPUT_FOLDER, ML_BEHAV_DAT_FILENAME));
            end

            if VERBOSE
                fprintf('\n');
            end
        end
        
        status = 0;
end % function
