function mltp_compute_best_fit_orientations_all_contexts(obj, session)
    outputFolder = fullfile(session.analysisFolder, obj.config.canon_square_placemaps_folder);

    % Allow the function to run so that other functions do not break,
    % but give a warning.
    sr = session.sessionRecord;
    if sr.getNumTrialsToProcess() < 2
        warning('This function requires the session to have more than 1 trial.');
    end
    
    numCells = length(session.tfiles_filename_prefixes);
    k = 1;
    vind = [];
    v = [];
    for iCell = 1:numCells
        fl = dir(fullfile(outputFolder, sprintf('%s_*_mltetrodeplacemapsquare.mat', session.tfiles_filename_prefixes{iCell})));
        fnames = {fl.name};
        
        % We need more than one map to perform a correlation since we don't
        % compute a correlation between a map and itself.
        if length(fnames) == 1
            warning('Not enough placemaps for (%s). A single unit must have more than one placemap in order to compute a correlation', ...
                session.tfiles_filename_prefixes{iCell});
        end

        for iMap1 = 1:length(fnames)
            x1 = load(fullfile(outputFolder, fnames{iMap1}));

            % Only compare maps that actually have spikes
            if x1.mltetrodeplacemap.totalSpikesAfterCriteria == 0
                continue;
            end

            T1 = x1.mltetrodeplacemap.meanFiringRateMapSmoothed;

            W1 = ones(size(T1));
            W1(isnan(T1)) = 0;

            for iMap2 = (iMap1+1):length(fnames)
                x2 = load(fullfile(outputFolder, fnames{iMap2}));
                                            % Only compare maps that actually have spikes
                if x2.mltetrodeplacemap.totalSpikesAfterCriteria == 0
                    continue;
                end

                T2 = x2.mltetrodeplacemap.meanFiringRateMapSmoothed;

                W2 = ones(size(T2));
                W2(isnan(T2)) = 0;

                fprintf('Computing pixel-pixel cross-correlation for cell %s between trial %d and trial %d\n', session.tfiles_filename_prefixes{iCell}, iMap1, iMap2);

                [v(k), vind(k)] = ml_core_max_pixel_rotated_pixel_cross_correlation_square(T1, T2, 'W1',W1,'W2',W2);
                k = k + 1;
            end
        end
    end

    %folder = fullfile(session.analysisFolder, obj.config.trial_nvt_position_plots_folder);
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder)
    end

    outputFilename = fullfile(outputFolder, 'best_fit_orientations_all_contexts.mat');
    fprintf('Saving best fit orientation data (all contexts) to file: %s\n', outputFilename);
    save(outputFilename, 'v', 'vind');  
end % function