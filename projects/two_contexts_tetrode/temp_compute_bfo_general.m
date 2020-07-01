function [perCell, total] = temp_compute_bfo_general(obj, session, rotDeg, mirrorContexts)
    % mirrorContexts should be the same length as the number of contexts
    % an entry of 0 means do not mirror, and 1 means to mirror
    % this is used because often context 2 has the reward cup mirrored
    
    % Allow the function to run so that other functions do not break,
    % but give a warning.
    if session.getNumTrialsToUse() < 2
        warning('This function requires the session to have more than 1 trial.');
    end
    
    if rotDeg == 90
        % We have to use the shrunk data if the shape is a rectangle
        if strcmpi(obj.getArena().shape, 'rectangle')
            outputFolder = fullfile(session.getAnalysisDirectory(), obj.Config.placemaps.outputFolderShrunk);
        else % square or cylinder
            outputFolder = fullfile(session.getAnalysisDirectory(), obj.Config.placemaps.outputFolder);
        end
    elseif rotDeg == 180
        outputFolder = fullfile(session.getAnalysisDirectory(), obj.Config.placemaps.outputFolder);
    else
        error('Invalid rotDeg (%f) given. Can only be 90 or 180.', rotDeg);
    end
    


    tfiles_filename_prefixes = session.getTFilesFilenamePrefixes();
    
    numCells = length(tfiles_filename_prefixes);
    
    % Will be the length of the number of cells
    perCell = struct('vind_same', [], 'v_same', [], ...
        'vind_different', [], 'v_different', [], ...
        'vind_all', [], 'v_all', []);
    
    for iCell = 1:numCells
        % Store a new cells results
        perCell(iCell).vind_same = [];
        perCell(iCell).v_same = [];
        perCell(iCell).vind_different = [];
        perCell(iCell).v_different = [];
        perCell(iCell).vind_all = [];
        perCell(iCell).v_all = [];

        
        fl = dir(fullfile(outputFolder, sprintf('%s_*_%s', tfiles_filename_prefixes{iCell}, obj.Config.placemaps.filenameSuffix)));
        fnames1 = {fl.name};
        
        % Now get a list of the the trials that we want to use so that we
        % dont assume that every placemap is used
        trialIdsToUse = session.getTrialIndicesToUse();
        fnames = {};
        for iName = 1:length(fnames1)
            tmp = split(fnames1{iName}, '_'); % eg. TT2_02_1_mltetrodeplacemaps.mat
            tid = str2double(tmp{2});
            if ismember(tid, trialIdsToUse)
                fnames{end+1} = fnames1{iName};
            end
        end

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




            W1 = ones(size(T1));
            %W1(x1.mltetrodeplacemap.visitedCountMap==0) = 0;
            W1(isnan(T1)) = 0;
            
            if mirrorContexts(context1) == 1
                T1 = fliplr(T1);
                W1 = fliplr(W1);
            end

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

                if mirrorContexts(context2) == 1
                    T2 = fliplr(T2);
                    W2 = fliplr(W2);
                end

                fprintf('Computing within-context pixel-pixel cross-correlation (%d) for cell %s between trial %d and trial %d\n', rotDeg, tfiles_filename_prefixes{iCell}, iMap1, iMap2);

                if rotDeg == 90
                    [vn, vindn] = ml_core_max_pixel_rotated_pixel_cross_correlation_90deg(T1, T2, 'W1',W1,'W2',W2);
                elseif rotDeg == 180
                    [vn, vindn] = ml_core_max_pixel_rotated_pixel_cross_correlation_180deg(T1, T2, 'W1',W1,'W2',W2);
                else
                    % this should be impossible
                    error('Logic error!');
                end
                
                % Now store the result in the appropriate locations
                if context1 == context2
                    perCell(iCell).v_same(end+1) = vn;
                    perCell(iCell).vind_same(end+1) = vindn;
                end
                
                if context1 ~= context2
                    perCell(iCell).v_different(end+1) = vn;
                    perCell(iCell).vind_different(end+1) = vindn;
                end
                
                perCell(iCell).v_all(end+1) = vn;
                perCell(iCell).vind_all(end+1) = vindn;
                
            end
        end
    end
    
    % Combine the per cell data
    total.vind_same = [];
    total.v_same = [];
    total.vind_different = [];
    total.v_different = [];
    total.vind_all = [];
    total.v_all = [];
    
    for iCell = 1:numCells
        total.vind_same = [total.vind_same, perCell(iCell).vind_same];
        total.v_same = [total.v_same, perCell(iCell).v_same];
        total.vind_different = [total.vind_different, perCell(iCell).vind_different];
        total.v_different = [total.v_different, perCell(iCell).v_different];
        total.vind_all = [total.vind_all, perCell(iCell).vind_all];
        total.v_all = [total.v_all, perCell(iCell).v_all];
    end
        
end % function