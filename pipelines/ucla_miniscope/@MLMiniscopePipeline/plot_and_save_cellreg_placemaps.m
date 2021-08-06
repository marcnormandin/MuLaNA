function plot_and_save_cellreg_placemaps(obj, session)

placemapDatabaseFilename = fullfile(session.getAnalysisDirectory(), sprintf('%s_placemaps.mat', session.getName()));

% All of the cell ids stored in the placemap database are local to the trial
placemapData = load(placemapDatabaseFilename);

uniqueCellIds = unique(placemapData.cellIds);
numCells = length(uniqueCellIds);

numCellsPerFigure = 5;
maxTrials = max(placemapData.trialIds);
k = 0;
figNum = 0;
hFig = figure('position', get(0, 'screensize'));
for iCell = 1:numCells
    if k == 0
        clf(hFig, 'reset');
        figNum = figNum+1;
    end
    k = k + 1;
    
    cellId = uniqueCellIds(iCell);
    inds = find(placemapData.cellIds == cellId);
    maps = placemapData.maps(:,:,inds);
    tids = placemapData.trialIds(inds);
    
    for iMap = 1:length(tids)
        pm = maps(:,:,iMap);
        subplot(numCellsPerFigure, maxTrials, (k-1)*maxTrials + tids(iMap))
        ml_imagesci(pm);
        axis equal tight off
        title(sprintf('C%dT%d', iCell, tids(iMap)));
        colormap jet
    end
    
    % Start a new figure
    if k == numCellsPerFigure
        % Save the figure
        outputFolder = fullfile(session.getAnalysisDirectory(), 'cellreg_placemaps');
        if ~exist(outputFolder, 'dir')
            mkdir(outputFolder);
        end
        saveas(hFig, fullfile(outputFolder, sprintf('cellreg_placemaps_%d.png', figNum)));
        k = 0;
    end
end
close(hFig);
