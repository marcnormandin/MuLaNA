% Transform the coordinates and then compute the speed in the new
% coordinates. This is normally used to convert from position in 
% video pixels to position in cm. Transforms from (p,q) to (x,y)
function [x,y, vtrans] = ml_core_geometry_homographic_transform_points(refP, refQ, refX, refY, p, q)
    % Validate the reference points. Make sure that the are all 1xN
    numRefPoints = length(refP);
    if any(numRefPoints ~= [numel(refP), numel(refQ), numel(refX), numel(refY)])
        error('Error. The sizes of the reference points do not match.');
    end
    
    % Validate the points in the original coordinate system
    if any(size(p) ~= size(q))
        error('Error. The sizes of p and q must be the same.');
    end
    
    % Store the size of p and q so we can return vectors having the same
    % size so. Example, if given row vectors, then return row vectors.
    originalShape = size(p);
    
    % We need these to be row vector 1xM, where M is the number of
    % reference points
    refP = reshape(refP, [1, length(refP)]);
    refQ = reshape(refQ, [1, length(refQ)]);
    refX = reshape(refX, [1, length(refX)]);
    refY = reshape(refY, [1, length(refY)]);
    
    % We need these to be row vectors 1xN
    p = reshape(p, [1, length(p)]);
    q = reshape(q, [1, length(q)]);
    
    % Get the transformation matrix
    vtrans = homography_solve([refP; refQ], [refX; refY]);

    % Tranform the points into the new coordinate system
    canonPts = homography_transform([p; q], vtrans);

    x = canonPts(1,:);
    y = canonPts(2,:);
   
    % Reshape to what p and q were
    x = reshape(x, originalShape);
    y = reshape(y, originalShape);
end % function
