classdef MLBehaviourWriterH5 < handle
    %MLBehaviourWriterH5 Writes arrays to an h5 file.
    %   Writes basic behaviour data from arrays to an h5 file.

    
    methods (Static)
        function write(filename, positionX, positionY, speed, headDirection, timestampsMs)
            arrayLength = length(positionX);
            
            % Check that the arrays are all the same length
            if ~all( size(positionX) == [1, arrayLength] )
                error('position_x is size (%d,%d) but should be (1,%d)', size(positionX,1), size(positionX,2), arrayLength);
            end

            % Check that the arrays are all the same length
            if ~all( size(positionY) == [1, arrayLength] )
                error('position_y is size (%d,%d) but should be (1,%d)', size(positionY,1), size(positionY,2), arrayLength);
            end

            % Check that the arrays are all the same length
            if ~all( size(speed) == [1, arrayLength] )
                error('speed is size (%d,%d) but should be (1,%d)', size(speed,1), size(speed,2), arrayLength);
            end

            % Check that the arrays are all the same length
            if ~all( size(headDirection) == [1, arrayLength] )
                error('head_direction is size (%d,%d) but should be (1,%d)', size(headDirection,1), size(headDirection,2), arrayLength);
            end

            % Check that the arrays are all the same length
            if ~all( size(timestampsMs) == [1, arrayLength] )
                error('timestamps_ms is size (%d,%d) but should be (1,%d)', size(timestampsMs,1), size(timestampsMs,2), arrayLength);
            end
            
            try 
                if isfile(filename)
                    delete(filename);
                end
                
                
               
                % Write the common array length
                %h5create(filename);
                
                
                % Write the arrays
                h5create(filename, '/position_x', [1, arrayLength]);
                h5write(filename, '/position_x', positionX);
                
                h5create(filename, '/position_y', [1, arrayLength]);
                h5write(filename, '/position_y', positionY);
                
                h5create(filename, '/speed', [1, arrayLength]);
                h5write(filename, '/speed', speed);
                
                h5create(filename, '/head_direction', [1, arrayLength]);
                h5write(filename, '/head_direction', headDirection);
                
                h5create(filename, '/timestamps_ms', [1, arrayLength]);
                h5write(filename, '/timestamps_ms', timestampsMs);
                
                h5writeatt(filename, '/', 'array_length', arrayLength);
                
            catch e
                error('Error while writing data to (%s): %s', filename, e.message);
                %rethrow(e)
            end
        end
    end % methods
end % classdef

