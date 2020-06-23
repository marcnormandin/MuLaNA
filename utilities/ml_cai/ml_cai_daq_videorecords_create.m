function [status, p] = ml_cai_daq_videorecords_create(trialFolder, dataFolder, subjectName, dataset, dateString, timeString, varargin)
    p = inputParser;
    p.CaseSensitive = false;
    
    addRequired(p,'trialFolder', @isstr);
    addRequired(p,'dataFolder', @isstr);
    addRequired(p,'subjectName', @isstr);
    addRequired(p,'dataset', @isstr);
    addRequired(p,'dateString', @isstr);
    addRequired(p,'timeString', @isstr);
    
    addParameter(p, 'scopeDatFilename', 'scope.dat', @isttr);
    addParameter(p, 'behavDatFilename', 'behav.dat', @isstr);
    addParameter(p, 'timestampFilename', 'timestamp.dat', @isttr);
    addParameter(p, 'notesFilename', 'settings_and_notes.dat', @isttr);
    addParameter(p, 'outputFolder', dataFolder, @isstr);
    addParameter(p, 'verbose', false, @islogical);
    
    % Output
    addParameter(p, 'outputScopeRecordFilename', 'scope.hdf5', @isstr);
    addParameter(p, 'outputBehavRecordFilename', 'behav.hdf5', @isstr);
    
    parse(p, trialFolder, dataFolder, subjectName, dataset, dateString, timeString, varargin{:});
    
    status = -1;
    
    if p.Results.verbose
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
    
    % The dataset name will be prefixed to all its associated files
    %dataset = 'CMG095_cheng_s1';
    %maxFramesPerVideo = 1000;
    %dateString = '7_24_2019';
    %c = split(pwd, '\');
    %timeString = c{end};
    %subjectName = 'CMG095';
    daqTimestampFilename = fullfile(trialFolder, p.Results.timestampFilename);
    daqSettingsAndNotesFilename = fullfile(trialFolder, p.Results.notesFilename);

    daqSettings = DAQSettingsAndNotes( daqSettingsAndNotesFilename );
    daqAllData = DAQTimeStamp( daqTimestampFilename );

    % Unique to the scope
    %scopeInfo.scope_led_excitation = daqSettings.excitation;
    %scopeInfo.scope_exposure = daqSettings.msCamExposure;

    lastModified = now;

    scopeDatFullFilename = fullfile(dataFolder, p.Results.scopeDatFilename);
    hasScopeDat = true;
    if ~isfile(scopeDatFullFilename)
        hasScopeDat = false;
    end
    
    if hasScopeDat
        scopeDat = DAQCamera(scopeDatFullFilename);
    end
    
    behavDatFullFilename = fullfile(dataFolder, p.Results.behavDatFilename);
    hasBehavDat = true;
    if ~isfile(behavDatFullFilename)
        hasBehavDat = false;
    end
    
    if hasBehavDat
        behavDat = DAQCamera(behavDatFullFilename);
    end

    if hasScopeDat
        scopeInfo.recordName = daqSettings.animal;
        scopeInfo.videoHardwareType = 'miniscope';
        scopeInfo.videoHardwareDescription = 'miniscope';
        scopeInfo.videoPrefix = scopeDat.videoFilenamePrefix;
        scopeInfo.videoSuffix = scopeDat.videoFilenameSuffix;
        scopeInfo.videoWidth = scopeDat.videoWidth;
        scopeInfo.videoHeight = scopeDat.videoHeight;
        scopeInfo.cameraId = scopeDat.cameraId;
        scopeInfo.fps = scopeDat.estFps;
        scopeInfo.fpsPercent = scopeDat.estFpsPercent;
        scopeInfo.maxFramesPerVideo = scopeDat.maxFramesPerVideo;
        scopeInfo.outputFilename = fullfile(p.Results.outputFolder, p.Results.outputScopeRecordFilename); %sprintf('%s_scope.hdf5', dataset);
        scopeInfo.daqData = daqAllData.CameraSubset( scopeInfo.cameraId );
        scopeInfo.recordType = 'raw';
        % All frames are considered good
        scopeInfo.frameQuality = zeros(1,length(scopeInfo.daqData.sysClock));
        scopeInfo.lastModified = lastModified;
    end

    if hasBehavDat
        behavInfo.videoHardwareDescription = 'MOKOSE 2K USB3.0 Digital Camera with 2.8-12mm Varifocal HD Lens 60FPS UVC';
        behavInfo.videoHardwareType = 'behaviour';
        behavInfo.videoPrefix = behavDat.videoFilenamePrefix; %'behavCam';
        behavInfo.videoSuffix = behavDat.videoFilenameSuffix; %'.avi';
        behavInfo.videoWidth = behavDat.videoWidth;
        behavInfo.videoHeight = behavDat.videoHeight;
        behavInfo.cameraId = behavDat.cameraId;
        behavInfo.fps = behavDat.estFps;
        behavInfo.fpsPercent = behavDat.estFpsPercent;
        behavInfo.maxFramesPerVideo = behavDat.maxFramesPerVideo;
        behavInfo.outputFilename = fullfile(p.Results.outputFolder, p.Results.outputBehavRecordFilename); %sprintf('%s_behav.hdf5', dataset);
        behavInfo.daqData = daqAllData.CameraSubset( behavInfo.cameraId );
        behavInfo.recordType = 'raw';
        behavInfo.recordName = daqSettings.animal;
        % All frames are considered good
        behavInfo.frameQuality = zeros(1,length(behavInfo.daqData.sysClock));
        behavInfo.lastModified = lastModified;
    end

    if hasScopeDat && hasBehavDat
        infos{1} = scopeInfo;
        infos{2} = behavInfo;
    elseif hasScopeDat
        infos{1} = scopeInfo;
    elseif hasBehavDat
        infos{1} = behavInfo;
    else
        error('No scopeDat or behavDat exists.')
    end

    nInfos = length(infos);
    for iInfo = 1:nInfos
        info = infos{iInfo};

        %function ML_CaI_video_record_create( info, subjectName, dateString, timeString
        % Delete the file if it already exists
        if exist( info.outputFilename, 'file')==2
            if p.Results.verbose
                fprintf('Deleting %s\n', info.outputFilename);
            end
          delete( info.outputFilename );
        end


        % Compute values that we will save
        N = length(info.daqData.sysClock);
        videoNum = zeros(1,N);
        frameNumLocal = zeros(1,N);
        frameNumGlobal = zeros(1,N);
        vn = 1;
        fnl = 1;
        for i = 1:N
            if fnl > info.maxFramesPerVideo
                vn = vn + 1;
                fnl = 1;
            end
            videoNum(i) = vn;
            frameNumLocal(i) = fnl;
            frameNumGlobal(i) = i;
            fnl = fnl + 1;
        end

        if p.Results.verbose
            fprintf('Saving data to %s ... ', info.outputFilename);
        end
        
        h5create(info.outputFilename, '/timestamp_ms', N, 'Datatype', 'uint64');
        h5write(info.outputFilename, '/timestamp_ms', uint64(info.daqData.sysClock'));

        h5create(info.outputFilename, '/videonum', N, 'Datatype', 'uint64');
        h5write(info.outputFilename, '/videonum', uint64(videoNum));

        h5create(info.outputFilename, '/framenum_global', N, 'Datatype', 'uint64');
        h5write(info.outputFilename, '/framenum_global', uint64(frameNumGlobal));

        h5create(info.outputFilename, '/framenum_local', N, 'Datatype', 'uint64');
        h5write(info.outputFilename, '/framenum_local', uint64(frameNumLocal));

        h5create(info.outputFilename, '/frame_quality', N, 'Datatype', 'uint64');
        h5write(info.outputFilename, '/frame_quality', uint64(info.frameQuality));

        h5writeatt(info.outputFilename, '/', 'last_modified', info.lastModified);

        h5writeatt(info.outputFilename, '/', 'record_name', info.recordName);
        h5writeatt(info.outputFilename, '/', 'record_type', info.recordType);
        h5writeatt(info.outputFilename, '/', 'num_frames', uint64(N));
        h5writeatt(info.outputFilename, '/', 'dataset_name', dataset);
        h5writeatt(info.outputFilename, '/', 'video_hardware_type', info.videoHardwareType);
        h5writeatt(info.outputFilename, '/', 'video_hardware_description', info.videoHardwareDescription);
        h5writeatt(info.outputFilename, '/', 'video_filename_prefix', info.videoPrefix);
        h5writeatt(info.outputFilename, '/', 'video_filename_suffix', info.videoSuffix);
        h5writeatt(info.outputFilename, '/', 'video_width', uint64(info.videoWidth));
        h5writeatt(info.outputFilename, '/', 'video_height', uint64(info.videoHeight));


        h5writeatt(info.outputFilename, '/', 'video_frames_per_second', uint64(info.fps));
        h5writeatt(info.outputFilename, '/', 'video_frames_per_second_percent', info.fpsPercent);

        h5writeatt(info.outputFilename, '/', 'video_max_frames_per_video', uint64(info.maxFramesPerVideo));
        h5writeatt(info.outputFilename, '/', 'record_date', dateString);
        h5writeatt(info.outputFilename, '/', 'record_time', timeString);
        h5writeatt(info.outputFilename, '/', 'subject_name', subjectName);
        h5writeatt(info.outputFilename, '/', 'lab_name', 'Muzzio Lab');
        
        if p.Results.verbose
            fprintf('done!\n');
        end
    end

    status = 0;
end % function
