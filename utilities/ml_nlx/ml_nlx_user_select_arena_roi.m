function [xVertices, yVertices] = ml_nlx_user_select_arena_roi( posX, posY, titleStr )
PLOT_CONVEX_HULL = true;

    
K = 10;

fprintf('ROI reference points will be asked for. Hit enter after points are selected.\n');


h = figure;
plot(posX, posY, 'b.')
hold on

if PLOT_CONVEX_HULL    
    % If not enough points are given, then this will throw exception
    try
        [convHullK, convHullAv] = convhull([posX', posY']);
        hullX = posX(convHullK);
        hullY = posY(convHullK);
        plot(hullX, hullY, 'k-', 'linewidth',1)
    catch e
        warning('Not enough points to draw the convex hull.');
    end
end
title( titleStr )
set(gca, 'ydir', 'reverse')

% Increase the limits so the user has more freedom to create points
a = gca;
set(gca, 'XLim', [a.XLim(1)-K, a.XLim(2)+K]);
set(gca, 'YLim', [a.YLim(1)-K, a.YLim(2)+K]);

axis equal
fprintf('Select arena vertices in a counterclockwise direction:\n');
[xVertices, yVertices] = getpts(h);

hold on


close(h)

fprintf('Done finding reference points.\n');

end % function
