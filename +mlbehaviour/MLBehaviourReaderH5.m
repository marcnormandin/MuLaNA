classdef MLBehaviourReaderH5 < mlbehaviour.MLBehaviourInterface
    %MLBehaviour Implementation of the interface. Reads from h5 files.
    %   An implementation of the interface that can read from h5 files.
    
    properties (SetAccess = protected, GetAccess = protected)
        Filename
        ArrayLength
        PositionX
        PositionY
        Speed
        HeadDirection
        TimestampsMs
    end
    
    methods
        function obj = MLBehaviourReaderH5(filename)            
            % Check that the file exists
            if ~isfile( filename )
                error('Cannot load from (%s) because it is not a file.', filename);
            end
            obj.Filename = filename;
            
            try 
                % Read the common array length
                obj.ArrayLength = h5readatt(filename, '/', 'array_length');
                if obj.ArrayLength <= 0
                    error('The array length in (%s) is less than or equal to zero.', filename);
                end

                % Read the array
                obj.PositionX = h5read(filename, '/position_x');
                obj.PositionY = h5read(filename, '/position_y');
                obj.Speed = h5read(filename, '/speed');
                obj.HeadDirection = h5read(filename, '/head_direction');
                obj.TimestampsMs = h5read(filename, '/timestamps_ms');
                
                % Check that the arrays are all the same length
                if ~all( size(obj.PositionX) == [1, obj.ArrayLength] )
                    error('position_x is size (%d,%d) but should be (1,%d)', size(obj.PositionX,1), size(obj.PositionX,2), obj.ArrayLength);
                end
                
                % Check that the arrays are all the same length
                if ~all( size(obj.PositionY) == [1, obj.ArrayLength] )
                    error('position_y is size (%d,%d) but should be (1,%d)', size(obj.PositionY,1), size(obj.PositionY,2), obj.ArrayLength);
                end
                
                % Check that the arrays are all the same length
                if ~all( size(obj.Speed) == [1, obj.ArrayLength] )
                    error('speed is size (%d,%d) but should be (1,%d)', size(obj.Speed,1), size(obj.Speed,2), obj.ArrayLength);
                end
                
                % Check that the arrays are all the same length
                if ~all( size(obj.HeadDirection) == [1, obj.ArrayLength] )
                    error('head_direction is size (%d,%d) but should be (1,%d)', size(obj.HeadDirection,1), size(obj.HeadDirection,2), obj.ArrayLength);
                end
                
                % Check that the arrays are all the same length
                if ~all( size(obj.TimestampsMs) == [1, obj.ArrayLength] )
                    error('timestamps_ms is size (%d,%d) but should be (1,%d)', size(obj.TimestampsMs,1), size(obj.TimestampsMs,2), obj.ArrayLength);
                end
            catch e
                error('Error while reading data from (%s): %s', filename, e.message);
            end
        end
        
        function [r] = getArrayLength(obj)
            r = obj.ArrayLength;
        end
        
        function [x] = getPositionX(obj)
            x = obj.PositionX;
        end
        
        function [y] = getPositionY(obj)
            y = obj.PositionY;
        end
        
        function [s] = getSpeed(obj)
            s = obj.Speed;
        end
        
        function [hd] = getHeadDirection(obj)
            hd = obj.HeadDirection;
        end
        
        function [ts] = getTimestampsMs(obj)
            ts = obj.TimestampsMs;
        end
        
    end
end

