classdef MLBehaviourTracker < handle
    %MLBehaviourTracker This class tracks mouse behaviour
    %   This class tracks mouse behaviour by finding the position(s)
    %   of LED(s) that are mounted on the mouses head.
    
    properties
        ledPos = [];
    end
    
    methods
        function obj = MLBehaviourTracker()
        end
       
        function runall(obj, videoFolder, mlvidrec, roi, ledColours, CONST_A, binnerize, gaussFiltFactor, scaleWithIntensity, CONST_FLOOR_WEIGHT, CONST_WALL_WEIGHT, CONST_OUTSIDE_WEIGHT)
            numColours = length(ledColours);
            obj.ledPos = cell(numColours,1);
            for iColour = 1:numColours
                obj.ledPos{iColour} = zeros( mlvidrec.numFrames, 3 );
            end

            backgroundFrame = im2double( roi.refFrame );
            weightFrame = MLBehaviourTracker.computeweightframe(roi, CONST_FLOOR_WEIGHT, CONST_WALL_WEIGHT, CONST_OUTSIDE_WEIGHT);

            % No video is loaded at the start
            videoNumLoaded = -1;
            globalFrameNum = 1;
            while true
                videoNumNeeded = mlvidrec.videoNum( globalFrameNum );
                if videoNumLoaded ~= videoNumNeeded
                    videoFilename = fullfile(videoFolder, sprintf('%s%d%s', mlvidrec.videoFilenamePrefix, videoNumNeeded, mlvidrec.videoFilenameSuffix));
                    fprintf('Loading %s ... ', videoFilename);
                    videoFrames = ml_cai_io_behavreadavi(videoFilename);
                    fprintf('done!\n');
                    videoNumLoaded = videoNumNeeded;

                    % Process all of the frames (which are local to the video file
                    % loaded).
                    numLocalFrames = length(videoFrames.mov);
                    local_ledPos = cell(numColours,1);
                    for iColour = 1:numColours
                        local_ledPos{iColour} = zeros(numLocalFrames, 3);
                    end
                    
                    % USE PARFOR
                    for localFrameNum = 1:numLocalFrames
                        %fprintf('Processing %d of %d ... \n', localFrameNum, numLocalFrames );
                        
                        % Get the frame
                        currentFrame = im2double( videoFrames.mov(localFrameNum).cdata );
                        
                        % Process frame
                        ledInfo = MLBehaviourTracker.findled( ledColours, currentFrame, backgroundFrame, weightFrame, CONST_A, binnerize, gaussFiltFactor, scaleWithIntensity );
                        %obj.ledGreen( globalFrameNum, : ) = lg;
                        %obj.ledRed( globalFrameNum, : ) = lr;
                        for iColour = 1:numColours
                            local_ledPos{iColour}( localFrameNum, : ) = ledInfo{iColour};
                        end
                            %local_ledRed( localFrameNum, : ) = lr;
                        %fprintf('done!\n');
                        
                        % On to the next
                        %globalFrameNum = globalFrameNum + 1;
                        %fprintf('frame completed.\n');
                    end
                    
                    for localFrameNum = 1:numLocalFrames
                        for iColour = 1:numColours
                            obj.ledPos{iColour}( globalFrameNum, : ) = local_ledPos{iColour}( localFrameNum, :);
                        end
                        %obj.ledRed( globalFrameNum, : )   = local_ledRed( localFrameNum, : );
                        
                        % On to the next
                        globalFrameNum = globalFrameNum + 1;
                    end
                end

                if globalFrameNum >= mlvidrec.numFrames
                    break
                end
            end
            
%             obj.findled_redgreen_kalman();            
        end % function 
        
    end % methods
    
    methods(Access = public)
        
        
    end
    
    methods (Static)
        function weightFrame = computeweightframe(roi, CONST_FLOOR_WEIGHT, CONST_WALL_WEIGHT, CONST_OUTSIDE_WEIGHT)
            % Pixel weights for regions of a video frame
            %CONST_OUTSIDE_WEIGHT = 0.0;
            %CONST_WALL_WEIGHT = 0.9;
            %CONST_FLOOR_WEIGHT = 1.0;
            
            % We want to apply a weight to the entire frame for finding the LEDs
            % Determine which area the pixels are associated with
            iq = zeros(1, numel(roi.refFrame));
            jq = zeros(1, numel(roi.refFrame));
            m = 0;
            % Column-wise list of indices into the frame
            for j = 1:size(roi.refFrame,2)
                for i = 1:size(roi.refFrame,1)
                    m = m + 1;
                    iq(m) = i;
                    jq(m) = j;
                end
            end
            inFloor = inpolygon(jq,iq, roi.inside.j, roi.inside.i);
            inFloorI = iq(inFloor);
            inFloorJ = jq(inFloor);
            inArena = inpolygon(jq,iq, roi.outside.j, roi.outside.i);
            inWall = inArena & ~inFloor;
            inWallI = iq(inWall);
            inWallJ = jq(inWall);

            % Outside the walls and floor
            weightFrame = CONST_OUTSIDE_WEIGHT * ones(size(roi.refFrame,1), size(roi.refFrame,2));
            
            % Walls
            for k = 1:length(inWallI)
                weightFrame(inWallI(k), inWallJ(k)) = CONST_WALL_WEIGHT;
            end

            % Floor
            for k = 1:length(inFloorI)
                weightFrame(inFloorI(k), inFloorJ(k)) = CONST_FLOOR_WEIGHT;
            end            
        end % function
        
        function [colourInfo, colourFrame] = findled( ledColours, currentFrame, backgroundFrame, weightFrame, CONST_A, binnerize, gaussFiltFactor, scaleWithIntensity)
            % frames must be im2double
            
            colourInfo = cell(length(ledColours),1);
            colourFrame = cell(length(ledColours),1);
            
            %CONST_A = 0.8;
            
            %ff = imgaussfilt( currentFrame - backgroundFrame, 1 );
            ff = currentFrame - backgroundFrame;
            
            if scaleWithIntensity == true
                ffHSV = rgb2hsv(ff);
            end
            
            % Divide the frame between bright and dark
            if binnerize == true
                hsv = rgb2hsv(ff);
                level = graythresh(hsv(:,:,3));
                bw = imbinarize(hsv(:,:,3), level);
            else
                bw = ones(size(ff));
            end
            
            % Keep only the bright pixels
            CF = bw .* currentFrame;
            
            if gaussFiltFactor > 0
                ff = imgaussfilt(CF, gaussFiltFactor);
            else
                ff = CF;
            end
            

            
            %ff = CF;
            
            a = CONST_A;
            
            numColours = length(ledColours);
            for iColour = 1:numColours
                % Form a frame of "redness"
                if strcmp(ledColours{iColour}, 'red')
                    colourness = ff(:,:,1).*( (ff(:,:,1) - a*ff(:,:,2)).*(ff(:,:,1) - a*ff(:,:,3)) ) ./ (ff(:,:,1) + ff(:,:,2) + ff(:,:,3));
                elseif strcmp(ledColours{iColour}, 'green')
                    colourness = ff(:,:,2).*( (ff(:,:,2) - a*ff(:,:,1)).*(ff(:,:,2) - a*ff(:,:,3)) ) ./ (ff(:,:,1) + ff(:,:,2) + ff(:,:,3));
                else
                    error('Only green and red colours are supported.');
                end
                
                if scaleWithIntensity == true
                    colourness = colourness .* ffHSV(:,:,3).^2;
                end
                
                colourness(isnan(colourness)) = 0;
                RF = colourness;
                RF = RF .* weightFrame;
                % Matlab 2018a requires max(max)
                %maxR = max(RF, [], 'all');
                maxR = max(max(RF));
                [maxR_i, maxR_j] = find(RF == maxR, 1, 'first');
                maxR_k = (maxR_j-1) * size(RF,1) + maxR_i;
                BWR = RF > 0;
                CCR = bwconncomp(BWR);
                SR = 1;
                for k = 1:length(CCR.PixelIdxList)
                    if ~isempty( find(CCR.PixelIdxList{k} == maxR_k, 1, 'first') )
                        SR = length(CCR.PixelIdxList{k});
                        break;
                    end
                end

                radR = sqrt(2*SR/pi);
                colourInfo{iColour} = [maxR_i, maxR_j, radR];
                colourFrame{iColour} = RF;
            end

        end % function
        
%         function findled_redgreen_kalman(obj)
%             % convert to seconds and floating point
%             t = double(obj.mlvidrec.timestamp_ms) ./ 1000.0;
%             dt = diff(t);
% 
%             % Initialization
%             xp = [obj.ledGreen(1,1), obj.ledGreen(1,2), 0, 0, obj.ledRed(1,1), obj.ledRed(1,2), 0, 0]';
%             Pp = eye(8);
%             Q = 5*eye(8);
% 
%             % Accept the initial values as the Kalman Filter values
%             obj.ledGreenKF(1,:) = [obj.ledGreen(1,1), obj.ledGreen(1,2)];
%             obj.ledRedKF(1,:) = [obj.ledRed(1,1), obj.ledRed(1,2)];
% 
%             for iFrame = 2:obj.mlvidrec.numFrames
%                 Fp = eye(8);
%                 Fp(1:4,5:8) = eye(4) * dt(iFrame-1);
% 
%                 % Prediction
%                 xk = Fp * xp;
%                 Pk = Fp * Pp * Fp' + Q;
%                 
%                 % Map from state-space to measurement-space
%                 Hk = eye(8);
%                 
%                 % The measurement (where we think the led is and its
%                 % velocity)
%                 vgi = 0; %obj.ledGreen(iFrame,1) - obj.ledGreen(iFrame-1,1);
%                 vgj = 0; %obj.ledGreen(iFrame,2) - obj.ledGreen(iFrame-1,2);
%                 vri = 0; %obj.ledRed(iFrame,1) - obj.ledRed(iFrame-1,1);
%                 vrj = 0; %obj.ledRed(iFrame,2) - obj.ledRed(iFrame-1,2);
%                 zk = [obj.ledGreen(iFrame,1), obj.ledGreen(iFrame,2), vgi, vgj, obj.ledRed(iFrame,1), obj.ledRed(iFrame,2), vri, vrj]';
%                 
%                 % Use the error radius for each led as the measurement
%                 % uncertainty
%                 Rk = eye(8);
%                 Rk(1,1) = obj.ledGreen(iFrame,3)/2;
%                 Rk(2,2) = obj.ledGreen(iFrame,3)/2;
%                 Rk(5,5) = obj.ledRed(iFrame,3)/2;
%                 Rk(6,6) = obj.ledRed(iFrame,3)/2;
% 
%                 % If the led positions are distinct, then update
%                 if abs(zk(1) - zk(5)) > 0 || abs(zk(2) - zk(6)) > 0
%                     % Update
%                     % See: https://en.wikipedia.org/wiki/Woodbury_matrix_identity
%                     Ku = Pk * Hk' *  inv(Hk * Pk * Hk' + Rk);
%                     xu = xk + Ku * (zk - Hk * xk);
%                     Pu = Pk - Ku * Hk * Pk;
%                     
%                     xp = xu;
%                     Pp = Pu;
%                 else
%                     xp = xk;
%                     Pp = Pk;
%                 end
%                
%                 obj.ledGreenKF(iFrame,:) = [xp(1), xp(2)];
%                 obj.ledRedKF(iFrame,:) = [xp(5), xp(6)];
%             end
%         end % function
    end % methods
end

