function mltp_nlx_mclust_plot_spikes_for_checking_bits(obj, session)
    % Get a list of the tfiles
    tFilenames = dir(fullfile(session.getSessionDirectory(), 'TT*.t'));
    nvtFilename = fullfile(session.getSessionDirectory(), obj.Config.nvt_filename);
    numTFiles = length(tFilenames);
    
    outputFolder = fullfile(session.getAnalysisDirectory(), 'tfile_diagnostics');
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end
    
    for iFile = 1:numTFiles
        tFilename = fullfile(session.getSessionDirectory(), tFilenames(iFile).name);
        h = ml_nlx_mclust_plot_spikes_for_checking_bits( nvtFilename, tFilename );
        
        tmp = split(tFilenames(iFile).name, '.');
        if length(tmp) ~= 2
            error('The t-files should be of the form TT*.t but is (%s)', tFilename);
        end
        tFilenamePrefix = tmp{1};
        
        filenamePrefix = fullfile(outputFolder, sprintf('%s_nlx_mclust_spikes', tFilenamePrefix));
        savefig(h, sprintf('%s.fig', filenamePrefix))
        saveas(h, sprintf('%s.png', filenamePrefix), 'png');
        close(h);
                
    end % iFile
end % function
