function create_climerics_matrix_average(obj, session)


tf = session.getAnalysisDirectory();
fn = fullfile(tf, sprintf('%s_ics.mat', session.getName()));
if ~isfile(fn)
    warning('Can not create ics matrix average because (%s) was not found.\n', fn);
    return;
end
fd = load(fn);

% Use cell-like cells OMG
cellClassifications = ones(size(fd.trialIds)); % by default use them all
sfpCellLikeFilename = fullfile(session.getAnalysisDirectory(), sprintf('%s_sfp_celllike.mat', session.getName()));
if ~isfile(sfpCellLikeFilename)
    warning('Unable to load the cell spatial footprint classifications. It should exist as %s, but does not. All cells will be used.', sfpCellLikeFilename);
else
    tmp = load(sfpCellLikeFilename);
    % override the default
    cellClassifications = tmp.sfp_celllike_global;
    fprintf('\t\tloaded cell classification from (%s).\n', sfpCellLikeFilename);
end
            

% Get the unique (trialID, contextId) pairs
[C, ~, ~] = unique([fd.trialIds, fd.contextIds], 'rows');

c1inds = find(C(:,2)==1);
c2inds = find(C(:,2)==2);
% trials sorted by context
matrix_trialIds = [c1inds; c2inds];

matrixLabels = {};
for k = 1:length(c1inds)
    matrixLabels{k} = sprintf('C1T%d', k);
end
for k = 1:length(c2inds)
    matrixLabels{k+length(c1inds)} = sprintf('C2T%d', k);
end

numTrials = length(matrix_trialIds);
numCells = fd.numCells;

M = nan(numTrials, numTrials, 1);

uniqueCellIds = unique(fd.cellIds);

% Average over cells
iRec = 1;
for iCell = 1:numCells
    cellId = uniqueCellIds(iCell);
    
    % If not a cell, then skip it
    if cellClassifications(cellId) == 0
        continue;
    end
    
    % Get all of the associated data
    inds = find(fd.cellIds == cellId);
    cell_ics = fd.ics(inds);
    cell_trialIds = fd.trialIds(inds);
    cell_contextIds = fd.contextIds(inds);
    %cell_classifications = cellClassifications(inds);
    
    % Compute the matrix
    for i = 1:numTrials
        for j = 1:numTrials
            if i == j
                continue; % skip the diagnonal
            end
            % These are the trial ids whose data we want to obtain
            t1 = matrix_trialIds(i);
            t2 = matrix_trialIds(j);

            subinds1 = find(cell_trialIds == t1);
            subinds2 = find(cell_trialIds == t2);
            
            if length(subinds1) ~= 1 || length(subinds2) ~= 1
                warning('something bad is happening\n');
                continue;
            end
            
%             if cell_classifications(subinds1) == 0 || cell_classifications(subinds2) == 0
%                 continue; % not a cell so skip it
%             end
            
            cell_ics_t1 = cell_ics(subinds1);
            cell_ics_t2 = cell_ics(subinds2);
            
            M(t1, t2, iRec) = abs(cell_ics_t1 - cell_ics_t2);
        end 
    end
    iRec = iRec + 1;
end %iCell

hFig = figure('position', get(0, 'screensize'));
Mmean = nanmean(M, 3);
imagesc(1:numTrials, 1:numTrials, Mmean)
xticks(1:numTrials);
yticks(1:numTrials);
xticklabels(matrixLabels)
yticklabels(matrixLabels)
colormap jet
title(sprintf('Climer ICS (smoothed maps)\n%s %s (%d cells)', fd.animalName, fd.sessionName, numCells), 'fontweight', 'bold', 'interpreter', 'none')
axis equal square tight
outputFolder = session.getAnalysisDirectory();
outputFilename = fullfile(outputFolder, sprintf('%s_ics_matrix_average_celllike.png', fd.sessionName));
saveas(hFig, outputFilename);
close(hFig);

end

%nb = 6;
% ne = 6;
%     rectangle('Position',[nb,nb,ne,ne],...
%               'Curvature',[0,0],...
%              'LineWidth',4,'LineStyle','-')

% for iContext = 1:numContexts
%     nb = sum( cids < contexts(iContext) ) + 1;
%     ne = sum( cids == contexts(iContext) );
% 
% 
%     rectangle('Position',[nb,nb,ne,ne],...
%               'Curvature',[0,0],...
%              'LineWidth',4,'LineStyle','-')
% end

