function mltp_compute_best_fit_orientations_0_180_per_cell(obj, session)
    % Allow the function to run so that other functions do not break,
    % but give a warning.
    sr = session.sessionRecord;
    if sr.getNumTrialsToProcess() < 2
        warning('This function requires the session to have more than 1 trial.');
    end
    
    placemapFolder = fullfile(session.analysisFolder, obj.config.canon_rect_placemaps_folder);

    numCells = length(session.tfiles_filename_prefixes);

    best_fit_orientations_per_cell = struct;
    for iCell = 1:numCells
        % e.g. TT3_1
        tfileLabel = session.tfiles_filename_prefixes{iCell};

        % Search the directory for all placemaps maps matching that
        % tfileLabel
        fl = dir(fullfile(placemapFolder, sprintf('%s_*_mltetrodeplacemaprect.mat', tfileLabel)));
        fnames = {fl.name};
        numFnames = length(fnames);

        % Note that we don't care (for this) the order that the
        % maps come in because every combination will be checked.
        % e.g. We make first compare TT3_2_1.mat with TT3_2_12.mat.
        % The data specific will be recorded so we can access that
        % later
        best_fit_orientations_per_cell(iCell).tfile_filename_prefix = tfileLabel;

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

        for iMap1 = 1:numFnames
            % This file should exist since we checked for it at
            % at the start of the function
            x1 = load(fullfile(placemapFolder, fnames{iMap1}));
            T1 = x1.mltetrodeplacemap.meanFiringRateMapSmoothed;
            W1 = ones(size(T1));
            W1(isnan(T1)) = 0;

            for iMap2 = (iMap1+1):numFnames
                % This file should exist since we checked for it at
                % at the start of the function
                x2 = load(fullfile(placemapFolder, fnames{iMap2}));
                T2 = x2.mltetrodeplacemap.meanFiringRateMapSmoothed;
                W2 = ones(size(T2));
                W2(isnan(T2)) = 0;

                fprintf('Computing per-cell pixel-pixel cross-correlation for cell %s between trial %d and trial %d\n', tfileLabel, iMap1, iMap2);

                % Only get the value comparing 0 degree (no
                % rotation) and 180 degrees.
                [v, vind] = ml_core_max_pixel_rotated_pixel_cross_correlation_rectangle(T1, T2, 'W1',W1,'W2',W2);

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

    outputFolder = placemapFolder; %fullfile(session.analysisFolder, obj.config.trial_nvt_position_plots_folder);
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder)
    end

    outputFilename = fullfile(outputFolder, 'best_fit_orientations_0_180_per_cell.mat');
    fprintf('Saving best fit orientation data (0 or 180) (per cell) to file: %s\n', outputFilename);
    save(outputFilename, 'best_fit_orientations_per_cell');
end % function