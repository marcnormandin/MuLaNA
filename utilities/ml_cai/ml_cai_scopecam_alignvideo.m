function [p] = ml_cai_scopecam_alignvideo( dataFolder, varargin )
    p = inputParser;
    p.CaseSensitive = false;
    
    addRequired(p,'dataFolder', @isstr);
    %addRequired(p, 'dataFolder', @isstr);
    addParameter(p, 'videoFolder', dataFolder, @isstr);
    addParameter(p, 'outputFolder', dataFolder, @isstr);
    addParameter(p, 'timestampFilename', 'timestamp.dat', @isttr);
    addParameter(p, 'notesFilename', 'settings_and_notes.dat', @isttr);
    addParameter(p, 'verbose', false, @islogical);
    addParameter(p, 'maxFramesPerVideo', 1000, @isscalar);
    addParameter(p, 'scopeVideoFilenamePrefix', 'msCam', @isstr);
    addParameter(p, 'scopeVideoFilenameSuffix', '.avi', @isstr);
    
    addParameter(p, 'spatialDownsampling', 3, @isscalar);
    addParameter(p, 'isNonRigid', true, @islogical);
    
    % Output
    addParameter(p, 'alignedFilename', 'msaligned.avi', @isstr);
    
    parse(p, dataFolder, varargin{:});
        
    if p.Results.verbose
        fprintf('Using the following settings:\n');
        disp(p.Results)
    end
    
    % Create the output folder if it doesn't already exist
    if ~isfolder(p.Results.outputFolder)
        if VERBOSE
            fprintf('Creating output folder (%s) ... ', p.Results.outputFolder);
        end
        mkdir(p.Results.outputFolder);
        if VERBOSE
            fprintf('done!\n');
        end
    end
    
    timestampFilename = fullfile(dataFolder,  p.Results.timestampFilename);
    settingsAndNotesFilename = fullfile(dataFolder, p.Results.notesFilename);
    
    % Align the separate video files into one aligned video
    alignedFilenameFull = [p.Results.outputFolder filesep p.Results.alignedFilename];
    if p.Results.verbose
        fprintf('Aligned scope video will be saved to %s.\n', alignedFilenameFull);
    end
    
    % Perform the alignment
    ms = men_msGenerateVideoObj(dataFolder, p.Results.scopeVideoFilenamePrefix, p.Results.scopeVideoFilenameSuffix, '.dat', timestampFilename, settingsAndNotesFilename, p.Results.maxFramesPerVideo);    
    ms = msNormCorre(p.Results.spatialDownsampling, p.Results.isNonRigid, alignedFilenameFull, ms);

    % Remove the vidObj since it causes MATLAB issues and isn't needed
    ms.vidObj = [];
    
    % Save the mat file
    fn = fullfile(p.Results.outputFolder, 'ms.mat');
    if p.Results.verbose
        fprintf('Saving ms MAT file to %s.\n', fn);
    end
    save( fn, 'ms', '-v7.3' );    
end % function
