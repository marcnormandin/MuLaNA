function mltp_nlx_mclust_remove_invalid_t_files(obj, session)
    % Get a list of the tfiles
    tFilenames = dir(fullfile(session.getSessionDirectory(), 'TT*.t'));
    nvtFilename = fullfile(session.getSessionDirectory(), obj.Config.nvt_filename);
    numTFiles = length(tFilenames);
    
    %[nlxNvtTimeStamps_mus, ExtractedX, ExtractedY, ExtractedAngle, ~, ~, ~] = Nlx2MatVT(  nvtFilename, [1, 1, 1, 1, 1, 1], 1, 1, 1 );
    [ts_mus, ~, ~, ~, ~, ~, ~] = ml_nlx_nvt_load( nvtFilename );
    
    
    % TEMP
    figure('name', session.getName())
    subplot(2,1,1)
    plot(1:length(ts_mus), ts_mus, 'k.')
    subplot(2,1,2)
    dt = diff(ts_mus);
    plot(1:length(dt), dt, 'r.');
    
    
    outputFolder = fullfile(session.getAnalysisDirectory(), 'tfile_diagnostics');
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end
    
    for iFile = 1:numTFiles
        tFilename = fullfile(session.getSessionDirectory(), tFilenames(iFile).name);
        process_t_file(obj, ts_mus, tFilename);
    end % iFile
    
    % We now need to update the list of t-files since it is possible that
    % some have been moved and so should not be used.
    session.updateListOfTFiles();
    
end % function

function process_t_file(obj, nlxNvtTimeStamps_mus, tFilename)
    try
        %fprintf('Checking suitability of (%s) using 32 bits\n', tFilename);
        
        %spikeTimes_mus = ml_nlx_load_mclust_spikes_as_mus(nlxNvtTimeStamps_mus, tFilename, -1);
        % Load it as 32 bit
        spikeTimes_mclust = ml_nlx_mclust_load_spikes_32bit(tFilename);
        spikeTimes_mus_32bit = spikeTimes_mclust .* 10^6;
        is32BitValid = ml_nlx_mclust_spiketimes_are_valid(nlxNvtTimeStamps_mus, spikeTimes_mus_32bit, false);

        %fprintf('Checking suitability of (%s) using 64 bits\n', tFilename);

        % Load it as 64 bit
        spikeTimes_mclust = ml_nlx_mclust_load_spikes_64bit(tFilename);
        spikeTimes_mus_64bit = spikeTimes_mclust .* 10^6;
        is64BitValid = ml_nlx_mclust_spiketimes_are_valid(nlxNvtTimeStamps_mus, spikeTimes_mus_64bit, false);
        
        if ~is32BitValid && ~is64BitValid
            error('(%s) is not valid for 32 bits or 64 bits', tFilename);
        else
            %fprintf('WINNER WINNER CHICKEN DINNER!\n\n');
            % SUCCESS!!!
        end
    catch e
       % There was an exception thrown so the bits are not valid
       [filePath, filename, ext] = fileparts(tFilename);
       invalidFolder = fullfile(filePath, 'invalid_t_files');
       if ~exist(invalidFolder, 'dir')
           mkdir(invalidFolder);
       end
       destFilename = fullfile(invalidFolder, sprintf('%s%s', filename, ext));
       fprintf('Found an invalid t-file. Moving from (%s) to (%s).\n', tFilename, destFilename);
       movefile(tFilename, destFilename);
    end
end
