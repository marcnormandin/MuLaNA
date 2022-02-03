function helper_bfo_save_data(outputFolder, perCell, rotDeg, group)
    numAngles = 360/rotDeg;
    
    numCells = length(perCell);

    avg_prob = zeros(1, numAngles);
    avg_corr = 0;
    num_prob = 0;
    num_corr = 0;
    prob = [];
    corr = [];
    for iCell = 1:numCells
        % Only include the non-nan data.
        x = perCell(iCell).(sprintf('prob_%s', group));
        if ~any(isnan(x))
            if ~isempty(x)
                avg_prob = avg_prob + x;
                num_prob = num_prob + 1;
            end
            
            if isempty(prob)
                prob = x;
            else
                prob(end+1,:) = x;
            end
        end
        
        % Only include the non-nan data.
        y = perCell(iCell).(sprintf('avg_corr_%s', group));
        if ~any(isnan(y))
            if ~isempty(y)
                avg_corr = avg_corr + y;
                num_corr = num_corr + 1;
            end
            
            if isempty(corr)
                corr = y;
            else
                corr(end+1,:) = y;
            end
        end
    end
    avg_prob = avg_prob ./ num_prob;
    avg_prob(~isfinite(avg_prob)) = 0;
    
    % another way to compute the mean and std
    mean_prob = mean(prob,1);
    std_prob = std(prob, 0, 1);
    
    mean_corr = mean(corr,1);
    std_corr = std(corr,0,1);
    
    avg_corr = avg_corr ./ num_corr;
    if ~isfinite(avg_corr)
        avg_corr = 0;
    end
    
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder)
    end

    outputFilename = fullfile(outputFolder, sprintf('bfo_%d_%s.mat', rotDeg, group));
    fprintf('Saving best fit orientation data (%s contexts) to file: %s\n', group, outputFilename);
    save(outputFilename, 'mean_prob', 'std_prob', 'avg_prob', ...
        'mean_corr', 'std_corr', 'avg_corr', 'numCells', 'num_prob', 'num_corr', 'rotDeg', 'numAngles');
end
