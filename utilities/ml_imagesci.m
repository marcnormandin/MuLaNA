function [h] = ml_imagesci(I)
    % This plots the data like imagesc, but uses pcolor so interpolation
    % can be used. We have to flip the coordinates to match imagesc.
    M = nan(size(I,1)+1, size(I,2)+1);
    M(1:size(I,1), 1:size(I,2)) = I;
    h = pcolor( M );
    shading interp;
    set(gca, 'ydir', 'reverse');
end % function
