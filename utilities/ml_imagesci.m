function ml_imagesci(I)
    % This plots the data like imagesc, but uses pcolor so interpolation
    % can be used. We have to flip the coordinates to match imagesc.
    pcolor( I );
    shading interp;
    set(gca, 'ydir', 'reverse');
end % function
