classdef DAQCamera < handle
    properties (SetAccess = public)
        cameraId = [];
        
        numFrames = [];
        maxFramesPerVideo = [];
        numVideos = [];
        estFps = [];
        estFpsPercent = [];
        
        videoWidth = [];
        videoHeight = [];
        videoFilenamePrefix = [];
        videoFilenameSuffix = [];
    end % properties
    
    methods
        
        function obj = DAQCamera( filename )
            if nargin == 1
                obj = readfile( obj, filename );
            elseif nargin > 1
                error('Filename is required.')
            end
        end
        
        function obj = readfile ( obj, filename )
            fid = fopen( filename );
            if fid == -1
                error(fprintf('Unable to open the camera file (%s).\n', filename))
            end

            % read the header to skip it
            headerLine = fgets(fid); % dummy read

            rows = textscan(fid,'%d\t%d\t%d\t%d\t%d\t%f\t%s\t%s\t%d\t%d');
            
            obj.cameraId = rows{1};
            obj.videoWidth = rows{2};
            obj.videoHeight = rows{3}; % ms
            obj.numFrames = rows{4};
            obj.estFps = rows{5};
            obj.estFpsPercent = rows{6};
            obj.videoFilenamePrefix = rows{7}{1};
            obj.videoFilenameSuffix = rows{8}{1};
            obj.numVideos = rows{9};
            obj.maxFramesPerVideo = rows{10};
            
            fclose(fid);
        end
        
        function obj = savefile( obj, filename )
            fileId = fopen(filename, 'w');
            fprintf(fileId, 'camNum\tvideoWidth\tvideoHeight\tnumFrames\testFps\testFpsPercent\tvideoFilenamePrefix\tvideoFilenameSuffix\tnumVideos\tmaxFramesPerVideo\n');
            
            fprintf(fileId, '%d\t%d\t%d\t%d\t%d\t%0.2f\t%s\t%s\t%d\t%d', obj.cameraId, obj.videoWidth, obj.videoHeight, obj.numFrames, obj.estFps, obj.estFpsPercent, ...
                obj.videoFilenamePrefix, obj.videoFilenameSuffix, obj.numVideos, obj.maxFramesPerVideo);
            
            fclose(fileId); 
        end
    end % methods
end % classdef
