function ml_util_draw_correlation_matrix_patches(M)
    colour = [1,1,1];

    m = size(M,1);
    n = size(M,2);

    x = 1:n;
    y = 1:m;

    edgesX = x - 0.5;
    edgesX(end+1) = edgesX(end) + 1;
    edgesY = y - 0.5;
    edgesY(end+1) = edgesY(end) + 1;

    hold on

    [px, py] = meshgrid(edgesX, edgesY);

    for i = 1:m
        for j = i+1:n
            patch([px(i,j+1), px(i,j), px(i+1,j), px(i+1,j+1)], [py(i,j+1), py(i,j), py(i+1,j), py(i+1,j+1)], [1,1,1], 'edgecolor', colour, 'facecolor', colour)
        end
    end
    %set(gca, 'visible', 'off')
end % function