function mltp_plot_bfo_90_ac_per_cell(obj, session)
    % We have to use the shrunk data if the shape is a rectangle
    if strcmpi(obj.getArena().shape, 'rectangle')
        dataFolder = fullfile(session.analysisFolder, obj.config.placemaps.outputFolderShrunk);
    else
        dataFolder = fullfile(session.analysisFolder, obj.config.placemaps.outputFolder);
    end
    
    % Load the data
    matFilename = fullfile(dataFolder, 'bfo_90_ac_per_cell.mat');
    if ~isfile(matFilename)
        error('The data file (%s) does not exist. Make sure it has been computed.\n', matFilename);
    end   
    tmp = load( matFilename );
    data = tmp.best_fit_orientations_per_cell;

    numCells = length(data);
    
    sr = session.sessionRecord;

    h = figure('Position', get(0,'Screensize'));
    
    % FixMe! Pick the number of subplots based on the number that will
    % actually be plotted
    p = 5; q = 5; k = 1;
    for iCell = 1:numCells

        cellName = data(iCell).tfile_filename_prefix;
        cellData = data(iCell).angle_index;

        numAngles = 4;
        angleCounts = zeros(1,numAngles);
        for iAngle = 1:numAngles
           angleCounts(iAngle) = sum(cellData==iAngle); 
        end
        anglePercent = angleCounts ./ length(cellData);

        subplot(p,q,k)
        k = k + 1;
        bar([0, 90, 180, 270], anglePercent)
        title(sprintf('%s', cellName), 'interpreter', 'none')
        grid on
        set(gca,'XTickLabel',{['0' char(176)], ['90' char(176)], ['180' char(176)], ['270' char(176)]})


    end % iCell
    % Save the figure
        %outputFolder = fullfile(session.analysisFolder);
        %outputFolder = fullfile(pwd,'for_Isabel');
        outputFolder = fullfile(session.analysisFolder, 'best_fit_orientations_per_cell');
        if ~exist(outputFolder, 'dir')
            mkdir(outputFolder)
        end
        F = getframe(h);
        fnPrefix = sprintf('%s_%s_bfo_90_ac_per_cell', obj.experiment.subjectName, sr.getName());
        imwrite(F.cdata, fullfile(outputFolder, sprintf('%s.png', fnPrefix)), 'png')
        savefig(h, fullfile(outputFolder, sprintf('%s.fig', fnPrefix)));
        saveas(h, fullfile(outputFolder, sprintf('%s.svg', fnPrefix)), 'svg');
        print('-painters', '-depsc', fullfile(outputFolder,sprintf('%s.eps', fnPrefix)))
        close(h);

end % function