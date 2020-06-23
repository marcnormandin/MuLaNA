function allFrames = ml_cai_io_scopereadavi_all(videoFolder, videoPrefix, videoSuffix)
    fileList = dir(fullfile(videoFolder, sprintf('%s*%s', videoPrefix, videoSuffix)));
    if isempty(fileList)
        error('No video files to process');
    end

    numFiles = length(fileList);
    fprintf('Found %d files to process.\n', numFiles);

    %% Read all of the scope frames to memory (hopefully there is enough RAM)
    allFrames = [];
    for iFile = 1:numFiles
        fname = fullfile(fileList(iFile).folder, fileList(iFile).name);
        fprintf('Reading frames from %s... ', fname);
        f = ml_cai_io_scopereadavi(fname);
        fprintf('done.\n');
        if isempty(allFrames)
            allFrames = f;
        else
            allFrames = cat(3, allFrames, f);
        end
    end
    %%
    numFrames = size(allFrames,3);
    fprintf('Read in %d frames from %d files.\n', numFrames, numFiles);
end
