function plot_cellreg_spatialfootprints(obj, session)

    outputFolder = fullfile(session.getAnalysisDirectory(), obj.Config.cellreg_spatialfootprints_plot.outputFolder);
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end

    numRegCells = session.getNumCells();
    fprintf('There are %d registered cells.\n', numRegCells);

    for iRegCell = 1:numRegCells
        [h, score] = session.plotCellSpatialFootprints(iRegCell);
        
        F = getframe(h);
        prefix = sprintf('%s%d', obj.Config.cellreg_spatialfootprints_plot.filenamePrefix, iRegCell);
        
        fprintf('Saving cellreg spatial footprints (%d of %d): %s ... ', iRegCell, numRegCells, prefix);

        imwrite(F.cdata, fullfile(outputFolder, sprintf('%s.png', prefix)), 'png')
        savefig(h, fullfile(outputFolder, sprintf('%s.fig', prefix)));
        saveas(h, fullfile(outputFolder, sprintf('%s.svg', prefix)), 'svg');
        print('-painters', '-depsc', fullfile(outputFolder, sprintf('%s.eps', prefix)))
        close(h);
        
        fprintf('done!\n');
    end % iRegCell
end % function