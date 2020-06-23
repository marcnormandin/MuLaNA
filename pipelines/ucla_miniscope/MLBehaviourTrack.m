classdef MLBehaviourTrack < handle
    properties
        % Pixel positions of the LEDs in pixel coordinates
        ledColours = {};
        ledPos = [];
        numColours = [];
        numPoints = [];
        timestamp_ms = [];
        
        timestamp_s;
        
        
        pos = [];
        dirRad = [];
        dirDeg = [];
        vel = [];        
        spe = [];
        lookRad = [];
        lookDeg = [];
        
        quality = [];
    end
    
    methods        
        function obj = MLBehaviourTrack( varargin )
            if nargin == 1
                % Assume it is a filename and load it
                filename = varargin{1};
                obj = load(obj, filename);
            elseif nargin == 3
                % ARGS = ledColours, ledPos, timestamp_ms
                ledColours = varargin{1};
                ledPos = varargin{2};
                timestamp_ms = varargin{3};
                
                if size(ledPos{1},2) ~= 3
                    error('led positions must be an (i,j,q) array')
                end
                
                obj.ledColours = ledColours;
                obj.timestamp_ms = timestamp_ms;
                obj.timestamp_s = double(timestamp_ms) ./ 1000.0;
                obj.ledPos = ledPos;
                obj.numColours = length(obj.ledPos);
                obj.numPoints = size(obj.ledPos{1},1);
                obj.quality = zeros(obj.numPoints,1);

                if obj.numColours < 1
                    error('Must one or more sets of led positions')
                end

                if length(obj.timestamp_ms) ~= obj.numPoints
                    error('The number of led positions does not match the number of timestamp values.');
                end

                obj = updateDerivedValues(obj);
            else
                error('Invalid arguments');
            end
        end
        
        function obj = update_led_positions_by_indices(obj, newLedPos, indices)
            % newLedPos should be a cell(NumColours,1) with array (i,j,q)
            if length(newLedPos) ~= obj.numColours
                error('Each colour must have a new LED position.');
            end
            
            if size(newLedPos{1},2) ~= 3
                error('Led positions should be an array of i,j,q');
            end
            
            if length(indices) ~= size(newLedPos{1},1)
                error('Mismatch between number of led positions and the number of indices')
            end
            
            %disp(newLedPos)
            %disp(indices)
            
            for index = 1:length(indices)
                for iColour = 1:obj.numColours
                    obj.ledPos{iColour}(indices(index),1) = double(newLedPos{iColour}(index,1));
                    obj.ledPos{iColour}(indices(index),2) = double(newLedPos{iColour}(index,2));
                    obj.ledPos{iColour}(indices(index),3) = double(newLedPos{iColour}(index,3));
                end
            end
            
            obj = updateDerivedValues(obj);
        end
        
        function obj = updateDerivedValues(obj)
           % Compute the centroid of the led positions
            centroidPos = zeros(obj.numPoints, 2);
            for iColour = 1:obj.numColours
                centroidPos(:,1) = centroidPos(:,1) + obj.ledPos{iColour}(:,1);
                centroidPos(:,2) = centroidPos(:,2) + obj.ledPos{iColour}(:,2);
            end
            
            centroidPos = double(centroidPos) ./ double(obj.numColours);
            obj.pos = centroidPos;

            % Compute the velocity of the centroid.
            % Set the first value to tbe same as the second to make
            % the number of velocity values the same as the number of
            % positions.
            %centroidVelocity = zeros(obj.numPoints, 2);
            t = double(obj.timestamp_ms) ./ 1000.0;
            dt = diff(t);
            dx = double(diff(obj.pos));
            centroidVelocity = dx ./ dt;

            obj.vel = [centroidVelocity(1,:); centroidVelocity];

            % Compute the angle of the velocity
            obj.dirRad = atan2( obj.vel(:,1), obj.vel(:,2) );
            % Convert from [-pi, pi] to [0,2pi]
            obj.dirRad(obj.dirRad < 0) = obj.dirRad(obj.dirRad < 0) + 2*pi;
            obj.dirDeg = rad2deg( obj.dirRad );

            % Compute the speed, which is the magnitude of the velocity
            obj.spe = sqrt( obj.vel(:,1).^2 + obj.vel(:,2).^2 );

            % Compute the angle from the first LED to the second LED
            obj.lookRad = zeros(obj.numPoints, 1);
            obj.lookDeg = zeros(obj.numPoints, 1);
            if obj.numColours == 2
                tmp1 = obj.ledPos{2}(:,1) - obj.ledPos{1}(:,1);
                tmp2 = obj.ledPos{2}(:,2) - obj.ledPos{1}(:,2);
                obj.lookRad = atan2(tmp1, tmp2);
                % Convert from [-pi, pi] to [0,2pi]
                obj.lookRad( obj.lookRad < 0 ) = obj.lookRad( obj.lookRad < 0 ) + 2*pi;
                obj.lookDeg = rad2deg(obj.lookRad);
            else
                warning('Can not compute the look direction because 2 LEDs are required, but %d are used.', obj.numColours)
            end

            % Set the quality to bad if any values are bad
            for iColour = 1:obj.numColours
                % The quality of the object is initialized as zero
                %obj.quality(:) = obj.quality(:) + obj.ledPos{iColour}(:,3); % CheckMe!
                
                obj.quality( isnan(obj.ledPos{iColour}(:,1)) ) = obj.quality( isnan(obj.ledPos{iColour}(:,1)) ) + 1;
                obj.quality( isnan(obj.ledPos{iColour}(:,2)) ) = obj.quality( isnan(obj.ledPos{iColour}(:,2)) ) + 1;
            end
            obj.quality( isnan(obj.pos) ) = obj.quality( isnan(obj.pos) ) + 1;
            obj.quality( isnan(obj.vel(:,1)) ) = obj.quality( isnan(obj.vel(:,1)) ) + 1;
            obj.quality( isnan(obj.vel(:,2)) ) = obj.quality( isnan(obj.vel(:,2)) ) + 1;
            obj.quality( isnan(obj.dirRad) ) = obj.quality( isnan(obj.dirRad) ) + 1;
            obj.quality( isnan(obj.dirDeg) ) = obj.quality( isnan(obj.dirDeg) ) + 1;
            obj.quality( isnan(obj.spe) ) = obj.quality( isnan(obj.spe) ) + 1;
            obj.quality( isnan(obj.lookRad) ) = obj.quality( isnan(obj.lookRad) ) + 1;
            obj.quality( isnan(obj.lookDeg) ) = obj.quality( isnan(obj.lookDeg) ) + 1;

            % If the speed is above 500 pixels / second, then set the
            % quality to bad
            obj.quality( obj.spe > 500 ) = obj.quality( obj.spe > 500 ) + 1; 
        end
        
        function obj = load( obj, inputFilename )
            obj.numColours = h5readatt(inputFilename, '/', 'num_leds');
            if obj.numColours < 1
                error('The number of colours is less than 1.');
            end
            obj.numPoints = h5readatt(inputFilename, '/', 'num_frames');
            obj.timestamp_ms = h5read(inputFilename, '/timestamp_ms');
            obj.timestamp_s = h5read(inputFilename, '/timestamp_s');
            if obj.numPoints ~= length(obj.timestamp_ms)
                error('Length of timestamp_ms does not equal the number of points.');
            end
            if obj.numPoints ~= length(obj.timestamp_s)
                error('Length of timestamp_s does not equal the number of points.');
            end
            
            obj.ledColours = cell(obj.numColours,1);
            for iColour = 1:obj.numColours
                obj.ledColours{iColour} = h5readatt(inputFilename, '/', sprintf('led_%d_colour', iColour));
            end
            obj.ledPos = cell(obj.numColours,1);
            for iColour = 1:obj.numColours
                obj.ledPos{iColour} = zeros(obj.numPoints,3); % i, j, q
                obj.ledPos{iColour}(:,1) = h5read(inputFilename, sprintf('/led_%d_pos_vid_pixel_i', iColour));
                obj.ledPos{iColour}(:,2) = h5read(inputFilename, sprintf('/led_%d_pos_vid_pixel_j', iColour));
                obj.ledPos{iColour}(:,3) = h5read(inputFilename, sprintf('/led_%d_pos_vid_pixel_q', iColour));
            end
            
            obj.pos = zeros(obj.numPoints, 2);
            obj.pos(:,1) = h5read(inputFilename, '/pos_vid_pixel_i');
            obj.pos(:,2) = h5read(inputFilename, '/pos_vid_pixel_j');
            obj.dirRad = h5read(inputFilename, '/dir_vid_rad');
            obj.dirDeg = h5read(inputFilename, '/dir_vid_deg');
            obj.vel = zeros(obj.numPoints, 2); 
            obj.vel(:,1) = h5read(inputFilename, '/vel_vid_pixel_per_sec_i');
            obj.vel(:,2) = h5read(inputFilename, '/vel_vid_pixel_per_sec_j');
            obj.spe = h5read(inputFilename, '/spe_vid_pixel_per_sec');
            obj.lookRad = h5read(inputFilename, '/look_vid_rad');
            obj.lookDeg = h5read(inputFilename, '/look_vid_deg');
            obj.quality = h5read(inputFilename, '/quality');
        
        end
        
        function save( obj, outputFilename )
            N = double(obj.numPoints);
            M = double(obj.numColours);

            for iColour = 1:M
                h5create(outputFilename, sprintf('/led_%d_pos_vid_pixel_i',iColour), N, 'Datatype', 'double');
                h5write(outputFilename, sprintf('/led_%d_pos_vid_pixel_i',iColour), double(obj.ledPos{iColour}(:,1)));
                h5create(outputFilename, sprintf('/led_%d_pos_vid_pixel_j',iColour), N, 'Datatype', 'double');
                h5write(outputFilename, sprintf('/led_%d_pos_vid_pixel_j',iColour), double(obj.ledPos{iColour}(:,2)));
                h5create(outputFilename, sprintf('/led_%d_pos_vid_pixel_q',iColour), N, 'Datatype', 'double');
                h5write(outputFilename, sprintf('/led_%d_pos_vid_pixel_q',iColour), double(obj.ledPos{iColour}(:,3)));
                
                h5writeatt(outputFilename, '/', sprintf('led_%d_colour', iColour), obj.ledColours{iColour});
            end
            
            h5writeatt(outputFilename, '/', 'num_leds', double(M));
            h5writeatt(outputFilename, '/', 'num_frames', double(N));


            % Position is defined as the location between the LEDs
            h5create(outputFilename, '/pos_vid_pixel_i', N, 'Datatype', 'double');
            h5write(outputFilename, '/pos_vid_pixel_i', double(obj.pos(:,1)));
            h5create(outputFilename, '/pos_vid_pixel_j', N, 'Datatype', 'double');
            h5write(outputFilename, '/pos_vid_pixel_j', double(obj.pos(:,2)));

            % Calculate the heading direction defined to be the direction
            % from the green led to the red led (a bias can be applied later).
            h5create(outputFilename, '/dir_vid_rad', N, 'Datatype', 'double');
            h5write(outputFilename, '/dir_vid_rad', obj.dirRad(:));
            h5create(outputFilename, '/dir_vid_deg', N, 'Datatype', 'double');
            h5write(outputFilename, '/dir_vid_deg', obj.dirDeg(:));
            
            h5create(outputFilename, '/vel_vid_pixel_per_sec_i', N, 'Datatype', 'double');
            h5write(outputFilename, '/vel_vid_pixel_per_sec_i', obj.vel(:,1));
            h5create(outputFilename, '/vel_vid_pixel_per_sec_j', N, 'Datatype', 'double');
            h5write(outputFilename, '/vel_vid_pixel_per_sec_j', obj.vel(:,2));
            
            h5create(outputFilename, '/spe_vid_pixel_per_sec', N, 'Datatype', 'double');
            h5write(outputFilename, '/spe_vid_pixel_per_sec', obj.spe(:));

            h5create(outputFilename, '/look_vid_rad', N, 'Datatype', 'double');
            h5write(outputFilename, '/look_vid_rad', obj.lookRad(:));
            h5create(outputFilename, '/look_vid_deg', N, 'Datatype', 'double');
            h5write(outputFilename, '/look_vid_deg', obj.lookDeg(:));
            
            h5create(outputFilename, '/quality', N, 'Datatype', 'double');
            h5write(outputFilename, '/quality', obj.quality(:));
            
            h5create(outputFilename, '/timestamp_ms', N, 'Datatype', 'double');
            h5write(outputFilename, '/timestamp_ms', double(obj.timestamp_ms(:)));
            h5create(outputFilename, '/timestamp_s', N, 'Datatype', 'double');
            h5write(outputFilename, '/timestamp_s', obj.timestamp_s(:));
        end
        
        function plot_position_all_scatter(obj)
            plot(obj.pos(:,2), obj.pos(:,1), 'b.')
        end
        
        function plot_position_one_scatter(obj, index)
            plot(obj.pos(index,2), obj.pos(index,1), 'b.')
        end
        
        function plot_led_position_one_scatter(obj, index)
            tf = ishold;
                       
            for iColour = 1:obj.numColours
                ledColour = obj.ledColours{iColour};
                if strcmp(ledColour, 'red')
                    plot(obj.ledPos{iColour}(index,2), obj.ledPos{iColour}(index,1), 'r.', 'markersize', 20)
                    hold on
                    %badIndex = find(obj.ledPos{iColour}(:,3) ~= 0);
                    %plot(obj.ledPos{iColour}(badIndex,2), obj.ledPos{iColour}(badIndex,1), 'mo', 'markersize', 2)
                    
                elseif strcmp(ledColour, 'green')
                    plot(obj.ledPos{iColour}(index,2), obj.ledPos{iColour}(index,1), 'g.', 'markersize', 20)
                    hold on
                    %badIndex = find(obj.ledPos{iColour}(:,3) ~= 0);
                    %plot(obj.ledPos{iColour}(badIndex,2), obj.ledPos{iColour}(badIndex,1), 'mo', 'markersize', 2)
                end
            end
            
            if tf
                hold on
            else
                hold off
            end
        end
        
        function plot_led_position_all_scatter(obj)
            tf = ishold;
                       
            for iColour = 1:obj.numColours
                ledColour = obj.ledColours{iColour};
                if strcmp(ledColour, 'red')
                    plot(obj.ledPos{iColour}(:,2), obj.ledPos{iColour}(:,1), 'r.')
                    hold on
                    %badIndex = find(obj.ledPos{iColour}(:,3) ~= 0);
                    %plot(obj.ledPos{iColour}(badIndex,2), obj.ledPos{iColour}(badIndex,1), 'mo', 'markersize', 2)
                    
                elseif strcmp(ledColour, 'green')
                    plot(obj.ledPos{iColour}(:,2), obj.ledPos{iColour}(:,1), 'g.')
                    hold on
                    %badIndex = find(obj.ledPos{iColour}(:,3) ~= 0);
                    %plot(obj.ledPos{iColour}(badIndex,2), obj.ledPos{iColour}(badIndex,1), 'mo', 'markersize', 2)
                end
            end
            
            if tf
                hold on
            else
                hold off
            end
        end % function
    end
end

