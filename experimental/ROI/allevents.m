function allevents(src,evt)
evname = evt.EventName;
    switch(evname)
        case{'MovingROI'}
            disp(['ROI moving Previous Position: ' mat2str(evt.PreviousPosition)]);
            disp(['ROI moving Current Position: ' mat2str(evt.CurrentPosition)]);
            
        case{'ROIMoved'}
            disp(['ROI moved Previous Position: ' mat2str(evt.PreviousPosition)]);
            disp(['ROI moved Current Position: ' mat2str(evt.CurrentPosition)]);
    end

end