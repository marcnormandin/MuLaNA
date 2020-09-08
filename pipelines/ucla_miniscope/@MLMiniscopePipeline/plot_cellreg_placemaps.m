function plot_cellreg_placemaps(obj, session)

    outputFolder = fullfile(session.getAnalysisDirectory(), obj.Config.cellreg_placemaps_plot.outputFolder);
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end

    numRegCells = session.getNumCells();
    fprintf('There are %d registered cells.\n', numRegCells);

    for iRegCell = 1:numRegCells
        h = session.plotCellMaps(iRegCell);
        
        F = getframe(h);
        prefix = sprintf('%s%d', obj.Config.cellreg_placemaps_plot.filenamePrefix, iRegCell);
        
        fprintf('Saving cellreg placemap (%d of %d): %s ... ', iRegCell, numRegCells, prefix);

        imwrite(F.cdata, fullfile(outputFolder, sprintf('%s.png', prefix)), 'png')
        savefig(h, fullfile(outputFolder, sprintf('%s.fig', prefix)));
        saveas(h, fullfile(outputFolder, sprintf('%s.svg', prefix)), 'svg');
        print('-painters', '-depsc', fullfile(outputFolder, sprintf('%s.eps', prefix)))
        close(h);
        
        fprintf('done!\n');
    end % iRegCell
end % function