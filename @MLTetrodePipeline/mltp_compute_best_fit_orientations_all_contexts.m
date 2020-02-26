function mltp_compute_best_fit_orientations_all_contexts(obj, session)
    outputFolder = fullfile(session.analysisFolder, obj.config.canon_square_placemaps_folder);

    numCells = length(session.tfiles_filename_prefixes);
    k = 1;
    vind = [];
    v = [];
    for iCell = 1:numCells
        fl = dir(fullfile(outputFolder, sprintf('%s_*_mltetrodeplacemapsquare.mat', session.tfiles_filename_prefixes{iCell})));
        fnames = {fl.name};

        for iMap1 = 1:length(fnames)
            x1 = load(fullfile(outputFolder, fnames{iMap1}));

            % Only compare maps that actually have spikes
            if x1.mltetrodeplacemap.totalSpikesAfterCriteria == 0
                continue;
            end

            T1 = x1.mltetrodeplacemap.meanFiringRateMapSmoothed;
            %T1 = x1.mltetrodeplacemap.meanFiringRateMap;
            %T1 = x1.mltetrodeplacemap.spikeCountMap;


            % Flip if it is the second context
            %if mod(iMap1,2) == 0
            %    T1 = fliplr(T1);
            %end

            W1 = ones(size(T1));
            %W1(x1.mltetrodeplacemap.visitedCountMap==0) = 0;
            W1(isnan(T1)) = 0;

%                             if ~x1.mltetrodeplacemap.isPlaceCell
%                                 continue
%                             end



            for iMap2 = (iMap1+1):length(fnames)
                x2 = load(fullfile(outputFolder, fnames{iMap2}));
                                            % Only compare maps that actually have spikes
                if x2.mltetrodeplacemap.totalSpikesAfterCriteria == 0
                    continue;
                end


                T2 = x2.mltetrodeplacemap.meanFiringRateMapSmoothed;
                %T2 = x2.mltetrodeplacemap.meanFiringRateMap;
                %T2 = x2.mltetrodeplacemap.spikeCountMap;

                %if mod(iMap2,2) == 0
                %    T2 = fliplr(T2);
                %end

                W2 = ones(size(T2));
                %W2(x2.mltetrodeplacemap.visitedCountMap==0) = 0;
                W2(isnan(T2)) = 0;

%                                 if ~x2.mltetrodeplacemap.isPlaceCell
%                                     continue
%                                 end

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