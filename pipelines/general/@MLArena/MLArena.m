classdef MLArena < handle
    properties
        shapeTypeStr;
        
        % The number of reference points, N
        numReferencePoints;
        
        % 2xN reference points in the video frame
        % (1,:) -> x
        % (2,:) -> y
        referencePointsVideo;
        
        % 2xN reference points in the canoncial frame
        referencePointsCanon;
        
        % Homography Transformation Matrix
        HomographyTransformMatrix
    end % properties
    
    methods
        function obj = MLArena(shapeTypeStr, referencePointsVideo, referencePointsCanon)
            obj.shapeTypeStr = shapeTypeStr;
            obj.referencePointsVideo = referencePointsVideo;
            obj.referencePointsCanon = referencePointsCanon;
            obj.numReferencePoints = size(obj.referencePointsVideo,2);
        end % function
        
        function [numReferencePoints] = getNumReferencePoints(obj)
            numReferencePoints = obj.numReferencePoints;
        end % function
        
        function [referencePointsVideo] = getReferencePointsVideo(obj)
            referencePointsVideo = obj.referencePointsVideo;
        end % function
        
        % Updates the reference points in the video frame. This allows the
        % GUI to be used to refine the reference points.
        function updateReferencePointsVideo(obj, referencePointsVideo)
            if ~all(size(referencePointsVideo) == size(obj.referencePointsVideo))
                error('Cannot update because the number of reference points has changed.');
            end
            obj.referencePointsVideo = referencePointsVideo;
            obj.numReferencePoints = size(obj.referencePointsVideo,2);
        end % function
        
        function [referencePointsCanon] = getReferencePointsCanon(obj)
            referencePointsCanon = obj.referencePointsCanon;
        end % function
        
        function [shapeTypeStr] = getShapeType(obj)
            shapeTypeStr = obj.shapeTypeStr;
        end % function
        
        % Transform from video to canonical coordinates
        function [xCan, yCan] = tranformVidToCanonPoints(obj, xVid, yVid)
            [xCan, yCan, trans] = ml_core_geometry_homographic_transform_points(...
                obj.referencePointsVideo(1,:), obj.referencePointsVideo(2,:), ...
                obj.referencePointsCanon(1,:), obj.referencePointsCanon(2,:), ...
                xVid, yVid);
            % Store the matrix
            obj.HomographyTransformMatrix = trans;
        end % function
        
        % Get the minimum rectangular bounds that the caononical reference
        % points will fit inside. This works for any shape.
        function [boundsX, boundsY] = getCanonicalBounds(obj)
            boundsX = [min(obj.referencePointsCanon(1,:)), max(obj.referencePointsCanon(1,:))];
            boundsY = [min(obj.referencePointsCanon(2,:)), max(obj.referencePointsCanon(2,:))];
        end % function
        
        % Returns a boolean array representing whether or not the given
        % points in canonical coordinates are interior to the arena.
        % Subclasses override this if they want.
        function [isInside] = inInterior(obj, xCan, yCan)
            [boundsX, boundsY] = obj.getCanonicalBounds();
            isInside = inpolygon(xCan, yCan, boundsX, boundsY);
        end % function
        
        % Returns whether this shape is the same type as the input
        function [r] = isShape(obj, shapeType)
            r = strcmpi(obj.getShapeType(), shapeType);
        end
        
        % Plot the reference points in video coordinates
        function plotVideo(obj)
            x = obj.referencePointsVideo(1,:);
            y = obj.referencePointsVideo(2,:);
            plot(x,y,'ko','markerfacecolor', 'k');
        end
        
        % Plot the reference points in canonical coordinates
        function plotCanon(obj)
            x = obj.referencePointsCanon(1,:);
            y = obj.referencePointsCanon(2,:);
            plot(x,y,'ko','markerfacecolor', 'k');
        end
        
    end % methods
end % classdef
