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

    save_ac(outputFolder, total.v_all, total.vind_all);
    save_wc(outputFolder, total.v_same, total.vind_same);
    save_dc(outputFolder, total.v_different, total.vind_different);
    save_per_cell(outputFolder, perCell);
    save_total(outputFolder, total);
    
end % function

function save_ac(outputFolder, v, vind)
    outputFilename = fullfile(outputFolder, 'bfo_90_ac.mat');
    fprintf('Saving best fit orientation data (all contexts) to file: %s\n', outputFilename);
    save(outputFilename, 'v', 'vind');  
end

function save_wc(outputFolder, v, vind)
    outputFilename = fullfile(outputFolder, 'bfo_90_wc.mat');
    fprintf('Saving best fit orientation data (within context) to file: %s\n', outputFilename);
    save(outputFilename, 'v', 'vind');
end

function save_dc(outputFolder, v, vind)
    outputFilename = fullfile(outputFolder, 'bfo_90_dc.mat');
    fprintf('Saving best fit orientation data (different context) to file: %s\n', outputFilename);
    save(outputFilename, 'v', 'vind');
end

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
