function [p] = ml_cai_behavcam_roi_create( dataFolder, varargin )
    p = inputParser;
    p.CaseSensitive = false;
    
    addRequired(p,'dataFolder', @isstr);
    
    addParameter(p, 'outputFolder', dataFolder, @isstr);
    addParameter(p, 'verbose', false, @islogical);
    addParameter(p, 'backgroundFrameFilenamePrefix', 'behavcam_background_frame', @isstr);
    addParameter(p, 'filenamePrefix', 'behavcam_roi', @isstr);
    addParameter(p, 'includeOtherROI', false, @islogical);
    addParameter(p, 'useGrayscale', true, @islogical);
    
    parse(p, dataFolder, varargin{:});
    
    if p.Results.verbose
        fprintf('Using the following settings:\n');
        disp(p.Results)
    end
    
    % Read in the reference frame
    referenceFrameFilename = fullfile(dataFolder, [p.Results.backgroundFrameFilenamePrefix '.png']);
    if p.Results.verbose
        fprintf('Reading in reference frame (%s) ... ', referenceFrameFilename);
    end
    referenceFrame = imread( referenceFrameFilename ); 
    if p.Results.verbose
        fprintf('Done!\n');
    end
    
    behavcam_roi = men_behaviour_user_select_arena_roi( referenceFrame, p.Results.includeOtherROI, p.Results.useGrayscale );
    
    hRoi = men_behaviour_roi_plot( behavcam_roi, p.Results.useGrayscale );
   
    % Save the MAT file
    fn = fullfile( p.Results.outputFolder, [p.Results.filenamePrefix '.mat']);
    if p.Results.verbose
        fprintf('Saving ROI mat file to %s ... ', fn);
    end
    save( fn, 'behavcam_roi' );
    if p.Results.verbose
        fprintf('done!\n');
    end
    
    % Save the FIG file
    fn = fullfile( p.Results.outputFolder, [p.Results.filenamePrefix '.fig']);
    if p.Results.verbose
        fprintf('Saving ROI figure to %s ... ', fn);
    end
    savefig( hRoi, fn, 'compact' );
    if p.Results.verbose
        fprintf('Done!\n');
    end
    
    % Save the PNG file
    fn = fullfile( p.Results.outputFolder, [p.Results.filenamePrefix '.png']);
    if p.Results.verbose
        fprintf('Saving ROI figure to %s ... ', fn);
    end
    saveas( hRoi, fn, 'png' );
    if p.Results.verbose
        fprintf('done!\n');
    end
    close(hRoi);
end % function
