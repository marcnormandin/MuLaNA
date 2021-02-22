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
            
            % Fix any duplicated timestamps
            obj.FixDuplicatedTimestamps();
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

            % The first sysClock value for each camera is junk, so set it to (near) zero
            % Don't first frame of all cameras to zero because it will mess
            % with finding duplicate timestamps
            cameraIds = obj.CameraIds();
            for iCamera = 1:obj.NumCameras()
                obj.sysClock( obj.cameraNum == cameraIds(iCamera) & obj.frameNum == 1 ) = iCamera; 
            end
            
            fclose(fid);
        end
        
        function obj = SaveFile( obj, timestampFilename )
            fileId = fopen(timestampFilename, 'w');
            fprintf(fileId, 'camNum\tframeNum\tsysClock\tbuffer\n');
            for i = 1:length(obj.sysClock)
                fprintf(fileId, '%d\t%d\t%d\t%d\n', obj.cameraNum(i), obj.frameNum(i), obj.sysClock(i), obj.bufferNum(i));
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
        
        function obj = AddTimeOffset( obj, timeOffset_ms )
            obj.sysClock = obj.sysClock + timeOffset_ms;
        end
        
%         function obj = AddFrameOffset( obj, frameOffset )
%            if frameOffset < 1
%                error('Frame offset must be a positive whole number.')
%            end           
%         end
        
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
                cameraIds = obj.CameraIds();
                for i = 1:length(cameraIds)
                   icamera = find(obj.cameraNum == cameraIds(i));
                   numFrames = length(icamera);
                   obj.frameNum(icamera) = reshape(1:numFrames, numFrames, 1);
                end
            end
            
            obj.frameNum = reshape(obj.frameNum, numel(obj.frameNum), 1);
        end
        
        function obj = Combine( obj, ts )
            if ~isa(ts, 'DAQTimeStamp')
                error('Can only combine with another DAQTimeStamp object.');
            end
            
            % Check if there are overlapping timestamps, which should not
            % happen
            if ~isempty(intersect(obj.sysClock, ts.sysClock))
                error('Cannot combine datasets as there are overlapping timestamps.')
            end
            
            obj.cameraNum = [obj.cameraNum; ts.cameraNum];
            obj.frameNum = [obj.frameNum; ts.frameNum];
            obj.sysClock = [obj.sysClock; ts.sysClock];
            obj.bufferNum = [obj.bufferNum; ts.bufferNum];
            
            % Relabel each cameras frame numbers so that there are no
            % duplicates (since we are combining two sets).
            cameraIds = obj.CameraIds();
            for i = 1:length(cameraIds)
               icamera = find(obj.cameraNum == cameraIds(i));
               numFrames = length(icamera);
               obj.frameNum(icamera) = reshape(1:numFrames, numFrames, 1);
            end
            
            % Start each sysclock low
            for i = 1:length(cameraIds)
                icamera = find(obj.cameraNum == cameraIds(i));
                low = obj.sysClock(icamera(1));
                obj.sysClock(icamera) = obj.sysClock(icamera) - low + i;
            end
        end
    end % methods
    
    methods(Access = private)
        function FixDuplicatedTimestamps(obj)
            cameraIds = obj.CameraIds();
            numCameras = length(cameraIds);

            for iCamera = 1:numCameras
                ci = find( obj.cameraNum == cameraIds(iCamera) );

                [~, unique_ind] = unique(obj.sysClock(ci));
                duplicate_ind = setdiff(1:length(ci), unique_ind);
                numDuplicates = length(duplicate_ind);

                k = 1;
                if numDuplicates > 0
                   fprintf('WARNING! Found (%d) duplicate timestamps for cameraId (%d).\n', numDuplicates, cameraIds(iCamera));
                   for iDup = 1:numDuplicates
                       while 1
                           oldValue = obj.sysClock( ci(duplicate_ind(iDup)) );
                           newValue = oldValue + k;
                           if isempty( find(obj.sysClock(ci) == newValue) )
                               % we can add this new value
                               fprintf('Changing sysClock: index (%d) for cameraId (%d) from (%d) to (%d)\n', ci(duplicate_ind(iDup)), cameraIds(iCamera), oldValue, newValue);
                               obj.sysClock(ci(duplicate_ind(iDup))) = newValue;
                               break;
                           else
                               % new a new proposed value
                               k = k + 1;
                               fprintf('Proposed new value is not available. Iterating.\n');
                           end
                       end
                   end % iDup
                end
            end % iCamera
        end
    end % private methods
end % classdef
