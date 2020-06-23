function roiChange(src,evt, x_px, y_px, roi, h1, h2)
global h1
global h2

evname = evt.EventName;
    switch(evname)
        case{'MovingROI'}
            disp(['ROI moving Previous Position: ' mat2str(evt.PreviousPosition)]);
            disp(['ROI moving Current Position: ' mat2str(evt.CurrentPosition)]);
                insidei = inROI(roi,x_px,y_px);
    set(h1, 'Visible', 'off');
    set(h2, 'Visible', 'off');
    delete(h1);
    delete(h2);
    %inFloor = inpolygon(x_px,y_px, roi.insid, roi.inside.i);
    %inFloorI = iq(inFloor);
    %clf(gcf)

    hold on
    x = x_px(find(insidei == 0));
    y = y_px(find(insidei == 0));
    h1 = plot(x, y, 'b.');
    hold on
    xx = x_px(find(insidei == 1));
    yy = y_px(find(insidei == 1));
    h2 = plot(xx,yy,'g.');
    %roi.draw()
    assignin('base', 'h1', h1);
    assignin('base', 'h2', h2);
    %roi.draw()
        case{'ROIMoved'}
            disp(['ROI moved Previous Position: ' mat2str(evt.PreviousPosition)]);
            disp(['ROI moved Current Position: ' mat2str(evt.CurrentPosition)]);
    end

    

    
end