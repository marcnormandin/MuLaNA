function mltp_compute_bfo_90_wc(obj, session)
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
    k = 1;
    vind = [];
    v = [];
    for iCell = 1:numCells
        fl = dir(fullfile(outputFolder, sprintf('%s_*_%s', session.tfiles_filename_prefixes{iCell}, obj.config.placemaps.filenameSuffix)));
        fnames = {fl.name};

        for iMap1 = 1:length(fnames)
            x1 = load(fullfile(outputFolder, fnames{iMap1}));

            % Only compare maps that actually have spikes
            if x1.mltetrodeplacemap.totalSpikesAfterCriteria == 0
                continue;
            end

            % Get the context
            context1 = x1.trial_context_id;

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

                % Get the context
                context2 = x2.trial_context_id;

                % Only compare if the two contexts are the
                % same
                if context1 ~= context2
                    continue;
                end

                % Only compare trials that we actually want
                % to use, as some are redos or not used
                % due to experimental problems.
                if x1.trial_use ~= 1 || x2.trial_use ~= 1
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

                fprintf('Computing within-context pixel-pixel cross-correlation for cell %s between trial %d and trial %d\n', session.tfiles_filename_prefixes{iCell}, iMap1, iMap2);

                [v(k), vind(k)] = ml_core_max_pixel_rotated_pixel_cross_correlation_square(T1, T2, 'W1',W1,'W2',W2);
                k = k + 1;
            end
        end
    end

    %folder = fullfile(session.analysisFolder, obj.config.trial_nvt_position_plots_folder);
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder)
    end

    outputFilename = fullfile(outputFolder, 'bfo_90_wc.mat');
    fprintf('Saving best fit orientation data (within context) to file: %s\n', outputFilename);
    save(outputFilename, 'v', 'vind');
end % function