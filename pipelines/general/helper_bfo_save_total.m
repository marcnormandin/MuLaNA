function helper_bfo_save_total(outputFolder, total, rotDeg)
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder)
    end
    
    outputFilename = fullfile(outputFolder, sprintf('bfo_%d_total.mat', rotDeg));
    fprintf('Saving best fit orientation data (total) to file: %s\n', outputFilename);
    save(outputFilename, 'total', 'rotDeg');
end
