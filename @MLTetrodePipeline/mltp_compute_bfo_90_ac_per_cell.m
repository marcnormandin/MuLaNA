function mltp_compute_bfo_90_ac_per_cell(obj, session)
    % Allow the function to run so that other functions do not break,
    % but give a warning.
    sr = session.sessionRecord;
    if sr.getNumTrialsToProcess() < 2
        warning('This function requires the session to have more than 1 trial.');
    end
    
    % We have to use the shrunk data if the shape is a rectangle
    if strcmpi(obj.getArena().shape, 'rectangle')
        outputFolder = fullfile(session.analysisFolder, obj.config.placemaps.outputFolderShrunk);
    else
        outputFolder = fullfile(session.analysisFolder, obj.config.placemaps.outputFolder);
    end

    numCells = length(session.tfiles_filename_prefixes);

    best_fit_orientations_per_cell = struct;
    for iCell = 1:numCells
        fl = dir(fullfile(outputFolder, sprintf('%s_*_%s', session.tfiles_filename_prefixes{iCell}, obj.config.placemaps.filenameSuffix)));
        fnames = {fl.name};

        best_fit_orientations_per_cell(iCell).tfile_filename_prefix = session.tfiles_filename_prefixes{iCell};

        best_fit_orientations_per_cell(iCell).angle_index = [];
        best_fit_orientations_per_cell(iCell).angle_value = [];
        best_fit_orientations_per_cell(iCell).context_1 = [];
        best_fit_orientations_per_cell(iCell).context_2 = [];
        best_fit_orientations_per_cell(iCell).total_spikes_1 = [];
        best_fit_orientations_per_cell(iCell).total_spikes_2 = [];
        best_fit_orientations_per_cell(iCell).use_context_1 = [];
        best_fit_orientations_per_cell(iCell).use_context_2 = [];
        best_fit_orientations_per_cell(iCell).trial_num_1 = [];
        best_fit_orientations_per_cell(iCell).trial_num_2 = [];

        for iMap1 = 1:length(fnames)
            x1 = load(fullfile(outputFolder, fnames{iMap1}));
            T1 = x1.mltetrodeplacemap.meanFiringRateMapSmoothed;
            W1 = ones(size(T1));
            W1(isnan(T1)) = 0;

            for iMap2 = (iMap1+1):length(fnames)
                x2 = load(fullfile(outputFolder, fnames{iMap2}));
                T2 = x2.mltetrodeplacemap.meanFiringRateMapSmoothed;
                W2 = ones(size(T2));
                W2(isnan(T2)) = 0;

                fprintf('Computing per-cell pixel-pixel cross-correlation for cell %s between trial %d and trial %d\n', session.tfiles_filename_prefixes{iCell}, iMap1, iMap2);

                [v, vind] = ml_core_max_pixel_rotated_pixel_cross_correlation_square(T1, T2, 'W1',W1,'W2',W2);

                best_fit_orientations_per_cell(iCell).angle_index = [best_fit_orientations_per_cell(iCell).angle_index, vind];
                best_fit_orientations_per_cell(iCell).angle_value = [ best_fit_orientations_per_cell(iCell).angle_value, v];
                best_fit_orientations_per_cell(iCell).context_1 = [best_fit_orientations_per_cell(iCell).context_1, x1.trial_context_id];
                best_fit_orientations_per_cell(iCell).context_2 = [best_fit_orientations_per_cell(iCell).context_2, x2.trial_context_id];
                best_fit_orientations_per_cell(iCell).total_spikes_1 = [best_fit_orientations_per_cell(iCell).total_spikes_1, x1.mltetrodeplacemap.totalSpikesAfterCriteria];
                best_fit_orientations_per_cell(iCell).total_spikes_2 = [best_fit_orientations_per_cell(iCell).total_spikes_2, x2.mltetrodeplacemap.totalSpikesAfterCriteria];
                best_fit_orientations_per_cell(iCell).use_context_1 = [best_fit_orientations_per_cell(iCell).use_context_1, x1.trial_use];
                best_fit_orientations_per_cell(iCell).use_context_2 = [best_fit_orientations_per_cell(iCell).use_context_1, x2.trial_use];
                best_fit_orientations_per_cell(iCell).trial_num_1 = [best_fit_orientations_per_cell(iCell).trial_num_1, x1.trial_num];
                best_fit_orientations_per_cell(iCell).trial_num_2 = [best_fit_orientations_per_cell(iCell).trial_num_2, x2.trial_num];
            end
        end
    end

    %folder = fullfile(session.analysisFolder, obj.config.trial_nvt_position_plots_folder);
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder)
    end

    outputFilename = fullfile(outputFolder, 'bfo_90_ac_per_cell.mat');
    fprintf('Saving best fit orientation data (per cell) to file: %s\n', outputFilename);
    save(outputFilename, 'best_fit_orientations_per_cell');
end % function