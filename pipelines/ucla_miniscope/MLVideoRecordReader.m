classdef MLVideoRecordReader < handle
    
    properties
        videoFolder
        mlvidrec % Video record to be displayed
        videoType % Color or BW
        numVideos
        videoNumLoaded
        videoFrames
        numFrames
    end
    
    methods
        function obj = MLVideoRecordReader( videoFolder, videoType, mlvidrec )
            if ~isa(mlvidrec, 'MLVideoRecord')
                error('Input argument must be of type MLVideoRecord')
            end
            
            if ~strcmp(videoType, 'behav') && ~strcmp(videoType,'scope')
                error('Video type must be scope or behav')
            end
            
            obj.videoNumLoaded = -1;
            obj.videoFolder = videoFolder;
            obj.videoType = videoType;
            obj.mlvidrec = mlvidrec;
            obj.numVideos = max(obj.mlvidrec.videoNum);
            obj.numFrames = obj.mlvidrec.numFrames;
        end
        
        function frame = get_frame(obj, globalFrameNum)
            if globalFrameNum < 1 || globalFrameNum > obj.mlvidrec.numFrames
                error('Requested frame does not exist.')
            end
            
            videoNumNeeded = obj.mlvidrec.videoNum( globalFrameNum );
            if videoNumNeeded ~= obj.videoNumLoaded
                fn = fullfile( obj.videoFolder, [obj.mlvidrec.videoFilenamePrefix num2str(videoNumNeeded) obj.mlvidrec.videoFilenameSuffix] );
                
                if strcmp(obj.videoType, 'behav')
                    obj.videoFrames = ml_cai_io_behavreadavi( fn );
                else
                    error('Only behaviour videos are supported at this time.')
                end
            end
            
            obj.videoNumLoaded = videoNumNeeded;
            
            localFrame = obj.mlvidrec.frameNumLocal( globalFrameNum );
            
            if strcmp(obj.videoType, 'behav')
                x = obj.videoFrames;
                x = x.mov(localFrame);
                frame = x.cdata;
            else
                error('Only behaviour videos are supported at this time.')
            end
        end
        
        
        function frame = get_frame_scope(obj, globalFrameNum)
            if globalFrameNum < 1 || globalFrameNum > obj.mlvidrec.numFrames
                error('Requested frame does not exist.')
            end
            
            videoNumNeeded = obj.mlvidrec.videoNum( globalFrameNum );
            if videoNumNeeded ~= obj.videoNumLoaded
                fn = fullfile( obj.videoFolder, [obj.mlvidrec.videoFilenamePrefix num2str(videoNumNeeded) obj.mlvidrec.videoFilenameSuffix] );
                
                if strcmp(obj.videoType, 'behav')
                    obj.videoFrames = ml_cai_io_behavreadavi( fn );
                elseif strcmp(obj.videoType, 'scope')
                    obj.videoFrames = ml_cai_io_scopereadavi( fn );
                else
                    error('Only behaviour videos are supported at this time.')
                end
            end
            
            obj.videoNumLoaded = videoNumNeeded;
            
            localFrame = obj.mlvidrec.frameNumLocal( globalFrameNum );
            
            if strcmp(obj.videoType, 'behav')
                x = obj.videoFrames;
                x = x.mov(localFrame);
                frame = x.cdata;
            elseif strcmp(obj.videoType, 'scope')
                x = obj.videoFrames;
                x = x.mov(localFrame);
                frame = x.cdata;
            else
                error('Only behaviour videos are supported at this time.')
            end
        end % version 2
    end
end

