function mltp_compute_bfo_90(obj, session)
    % We have to use the shrunk data if the shape is a rectangle
    if strcmpi(obj.getArena().shape, 'rectangle')
        outputFolder = fullfile(session.getAnalysisDirectory(), obj.Config.placemaps.outputFolderShrunk);
    else
        outputFolder = fullfile(session.getAnalysisDirectory(), obj.Config.placemaps.outputFolder);
    end

    rotDeg = 90;
    mirrorContexts = [0 0]; % Mirror the second context
    
    [perCell, total] = mltp_compute_bfo_general(obj, session, rotDeg, mirrorContexts);

    %folder = fullfile(session.getAnalysisDirectory(), obj.Config.trial_nvt_position_plots_folder);
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder)
    end

    % Compute the averages
    
    
    save_data(outputFolder, perCell, 'same');
    save_data(outputFolder, perCell, 'different');
    save_data(outputFolder, perCell, 'all');
    save_per_cell(outputFolder, perCell);
    save_total(outputFolder, total);
    
end % function

function save_data(outputFolder, perCell, group)
    numCells = length(perCell);

    avg_prob = [0,0,0,0];
    avg_corr = 0;
    num_prob = 0;
    num_corr = 0;
    for iCell = 1:numCells
        % Only include the non-nan data.
        x = perCell(iCell).(sprintf('prob_%s', group));
        if ~any(isnan(x))
            avg_prob = avg_prob + x;
            num_prob = num_prob + 1;
        end
        
        % Only include the non-nan data.
        y = perCell(iCell).(sprintf('avg_corr_%s', group));
        if ~any(isnan(y))
            avg_corr = avg_corr + y;
            num_corr = num_corr + 1;
        end
    end
    avg_prob = avg_prob ./ num_prob;
    avg_prob(~isfinite(avg_prob)) = 0;
    
    avg_corr = avg_corr ./ num_corr;
    if ~isfinite(avg_corr)
        avg_corr = 0;
    end

    outputFilename = fullfile(outputFolder, sprintf('bfo_90_%s.mat', group));
    fprintf('Saving best fit orientation data (%s contexts) to file: %s\n', group, outputFilename);
    save(outputFilename, 'avg_prob', 'avg_corr', 'numCells', 'num_prob', 'num_corr');
end

% function save_wc(outputFolder, v, vind)
%     outputFilename = fullfile(outputFolder, 'bfo_90_wc.mat');
%     fprintf('Saving best fit orientation data (within context) to file: %s\n', outputFilename);
%     save(outputFilename, 'v', 'vind');
% end
% 
% function save_dc(outputFolder, v, vind)
%     outputFilename = fullfile(outputFolder, 'bfo_90_dc.mat');
%     fprintf('Saving best fit orientation data (different context) to file: %s\n', outputFilename);
%     save(outputFilename, 'v', 'vind');
% end

function save_total(outputFolder, total)
    outputFilename = fullfile(outputFolder, 'bfo_90_total.mat');
    fprintf('Saving best fit orientation data (total) to file: %s\n', outputFilename);
    save(outputFilename, 'total');
end

function save_per_cell(outputFolder, perCell)
    outputFilename = fullfile(outputFolder, 'bfo_90_per_cell.mat');
    fprintf('Saving best fit orientation data (per cell) to file: %s\n', outputFilename);
    save(outputFilename, 'perCell');
end
