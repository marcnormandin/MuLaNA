function mlgp_plot_bfo_general_session_grouped(obj, session, rotDeg)
    % This function is used by the pipeline and supplied with either
    % rotDeg = 90 or 180. It plots the groups best fit orientations.
    
    dataFilename = fullfile(session.getAnalysisDirectory(), obj.Config.best_fit_orientations.outputFolder, ...
        sprintf('bfo_%d_percell.mat', rotDeg));
    if ~isfile(dataFilename)
        error('The required file (%s) does not exist.', dataFilename);
    end
    
    data = load(dataFilename);
    if rotDeg ~= data.rotDeg
        error('Loaded the wrong percell data file!');
    end

    perCell = data.perCell;
    numCells = length(perCell);

    numAngles = 360/rotDeg;
    angles = (0:numAngles-1)*rotDeg;

    %groups = {'same', 'different', 'all'};
    groups = helper_bfo_percell_get_groups(perCell);
    
    numGroups = length(groups);
    groupMean = zeros(numGroups, numAngles);
    groupStd = zeros(numGroups, numAngles);
    for iGroup = 1:numGroups
        group = groups{iGroup};
        
        prob = []; %zeros(numCells, numAngles);
        for iCell = 1:numCells
            if length(perCell(iCell).('vind_all')) >= 32
                % use the data
                pc = perCell(iCell).(sprintf('prob_%s', group));
                if isempty(prob)
                    prob = pc;
                else
                    prob(end+1,:) = pc;
                end
            else
                % skip the data
            end
        end
        
        x1 = mean(prob,1, 'omitnan');
        x2 = std(prob,0,1, 'omitnan') ./ sqrt(size(prob,1));
        
        if ~isempty(x1)
            groupMean(iGroup,:) = x1;
        end
        
        if ~isempty(x2)
            groupStd(iGroup,:) = x2;
        end
    end

    h = figure;
    ml_util_bfo_errorbar_groups(angles, groupMean, groupStd)
    legend(groups)
    title(sprintf('Best Fit Orientations\n%s (%s)', obj.Experiment.getAnimalName(), session.getName()), 'interpreter', 'none')

    outputFolder = fullfile(session.getAnalysisDirectory(), obj.Config.best_fit_orientations.outputFolder);
    F = getframe(h);

    prefix = sprintf('bfo_%d_grouped', rotDeg);
    imwrite(F.cdata, fullfile(outputFolder, sprintf('%s.png', prefix)), 'png')
    savefig(h, fullfile(outputFolder, sprintf('%s.fig', prefix)));
    saveas(h, fullfile(outputFolder, sprintf('%s.svg', prefix)), 'svg');
    print('-painters', '-depsc', fullfile(outputFolder, sprintf('%s.eps', prefix)))
    close(h);
    
    % save the data that was computed
    save( fullfile(outputFolder, sprintf('bfo_%d_grouped.mat', rotDeg)), 'numGroups', 'groupMean', 'groupStd', 'groups', 'rotDeg', ...
        'numAngles', 'angles', 'numCells');
end % function

