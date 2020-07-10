function helper_bfo_save_percell(outputFolder, perCell, rotDeg)
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder)
    end
    
    outputFilename = fullfile(outputFolder, sprintf('bfo_%d_percell.mat', rotDeg));
    fprintf('Saving best fit orientation data (per cell) to file: %s\n', outputFilename);
    save(outputFilename, 'perCell', 'rotDeg');
end
