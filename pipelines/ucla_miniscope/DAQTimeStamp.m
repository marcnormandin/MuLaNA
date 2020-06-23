classdef DAQTimeStamp < handle
    properties (SetAccess = private)
        cameraNum = [];
        frameNum = [];
        sysClock = [];
        bufferNum = [];
    end % properties
    
    methods
        function obj = DAQTimeStamp( timestampFilename )
            if nargin == 1
                obj = ReadFile( obj, timestampFilename );
            elseif nargin > 1
                error('Filename is required.')
            end
        end
        
        function obj = ReadFile ( obj, timestampFilename )
            if ~isfile( timestampFilename )
                error('The file (%s) does not exist.', timestampFilename);
            end
            
            fid = fopen( timestampFilename );
            if fid == -1
                error(fprintf('Unable to open the timestamp file (%s).\n', timestampFilename))
            end

            % read the header to skip it
            headerLine = fgets(fid); % dummy read

            rows = textscan(fid,'%f\t%f\t%f\t%f');
            obj.cameraNum = rows{1};
            obj.frameNum = rows{2};
            obj.sysClock = rows{3}; % ms
            obj.bufferNum = rows{4};

            % The first sysClock value for each camera is junk, so set it to zero
            obj.sysClock( obj.frameNum == 1 ) = 0; 

            fclose(fid);
        end
        
        function obj = SaveFile( obj, timestampFilename )
            fileId = fopen(timestampFilename, 'w');
            fprintf(fileId, 'camNum\tframeNum\tsysClock\tbuffer\n');
            for i = 1:length(obj.sysClock)
                fprintf(fileId, '%d\t%d\t%d\t%d\n', obj.cameraNum, obj.frameNum(i), obj.sysClock(i), obj.bufferNum(i));
            end
            fclose(fileId); 
        end
        
        function x = NumCameras( obj )
            x = length( unique(obj.CameraIds) );
        end
        
        function x = CameraIds( obj )
            x = unique(obj.cameraNum);
        end
        
        function tsCam = CameraSubset( obj, cameraId )
            matchingIndices = find( obj.cameraNum == cameraId );
            if isempty(matchingIndices)
                error(fprintf("The DAQTimeStamp object doesn't contain data for the requested camera id (%d).\n", cameraId));
            end

            tsCam = DAQTimeStamp;
            tsCam.cameraNum = obj.cameraNum( matchingIndices );
            tsCam.frameNum  = obj.frameNum ( matchingIndices );
            tsCam.sysClock  = obj.sysClock ( matchingIndices );
            tsCam.bufferNum    = obj.bufferNum   ( matchingIndices );
        end
        
        function obj = Filter( obj, keepIndices, relabelFrames )
            if length( keepIndices ) ~= length( obj.frameNum )
                error('Error. DAQTimeStamp::filter requires keepIndices to be the same length as the object data.')
            end

            if nargin < 3
                relabelFrames = true;
            end
            
            %keepIndices = find( filterFlags == 1 );

            obj.cameraNum = obj.cameraNum( keepIndices );
            obj.frameNum  = obj.frameNum( keepIndices );
            obj.sysClock  = obj.sysClock(keepIndices);
            obj.bufferNum = obj.bufferNum( keepIndices);
            
            if relabelFrames
                obj.frameNum = 1:length(obj.sysClock);
            end
        end
        
        function obj = Combine( obj, ts )
            if ~isa(ts, 'DAQTimeStamp')
                error('Can only combine with another DAQTimeStamp object.');
            end
            
            obj.cameraNum = [obj.cameraNum; ts.cameraNum];
            obj.frameNum = [obj.frameNum; ts.frameNum];
            obj.sysClock = [obj.sysClock; ts.sysClock];
            obj.bufferNum = [obj.bufferNum; ts.bufferNum];
        end
    end % methods
end % classdef
