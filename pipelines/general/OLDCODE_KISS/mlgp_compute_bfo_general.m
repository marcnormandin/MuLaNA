function [perCell, total] = mlgp_compute_bfo_general(obj, session, rotDeg, mirrorContexts)
    % mirrorContexts should be the same length as the number of contexts
    % an entry of 0 means do not mirror, and 1 means to mirror
    % this is used because often context 2 has the reward cup mirrored
    
    % Allow the function to run so that other functions do not break,
    % but give a warning.
    if session.getNumTrialsToUse() < 2
        warning('This function requires the session to have more than 1 trial.');
    end
    
    if rotDeg == 90
        numAngles = 4;
        
        % We have to use the shrunk data if the shape is a rectangle
        if strcmpi(obj.Experiment.getArenaGeometry().shape, 'rectangle')
            placemapType = 'shrunk';
        else % square or cylinder
            placemapType = 'actual';
        end
    elseif rotDeg == 180
        numAngles = 2;
        placemapType = 'actual';
    else
        error('Invalid rotDeg (%f) given. Can only be 90 or 180.', rotDeg);
    end
    
    % Load whether to use the cells or not
    use_cell_per_trial = {};
    if obj.Config.use_spatial_footprint_filter == 1
        fprintf('The spatial footprint filter will be used.\n');
        for iTrial = 1:session.getNumTrials()
            trial = session.getTrial(iTrial);
            tmp = load(fullfile(trial.getAnalysisDirectory(), 'cell_use.mat'), 'cell_use');
            use_cell_per_trial{iTrial} = tmp.cell_use;
        end
    end
    
    numCells = session.getNumCells();
    fprintf('We will process %d cells.\n', numCells);
    
    numContexts = obj.Experiment.getNumContexts();
    
    % Will be the length of the number of cells
    perCell = struct('vind_same', [], 'v_same', [], 'prob_same', [], 'avg_corr_same', [], ...
        'vind_different', [], 'v_different', [], 'prob_different', [], 'avg_corr_different', [], ...
        'vind_all', [], 'v_all', [], 'prob_all', [], 'avg_corr_all', []);
    for iContext = 1:numContexts
       perCell.(sprintf('vind_context%d', iContext)) = []; 
       perCell.(sprintf('v_context%d', iContext)) = []; 
    end
    
    for iCell = 1:numCells
        % Store a new cells results
        perCell(iCell).vind_same = [];
        perCell(iCell).v_same = [];
        perCell(iCell).prob_same = [];
        perCell(iCell).avg_corr_same = [];
        
        perCell(iCell).vind_different = [];
        perCell(iCell).v_different = [];
        perCell(iCell).prob_different = [];
        perCell(iCell).avg_corr_different = [];
        
        perCell(iCell).vind_all = [];
        perCell(iCell).v_all = [];
        perCell(iCell).prob_all = [];
        perCell(iCell).avg_corr_all = [];
        
        for iContext = 1:numContexts
           perCell(iCell).(sprintf('vind_context%d', iContext)) = []; 
           perCell(iCell).(sprintf('v_context%d', iContext)) = []; 
        end
        
        perCell(iCell).cell_name = num2str(iCell);

        pmlist = session.getCellPlacemaps(iCell, placemapType);
        
        sfpValid = ones(1, length(pmlist)); % by default dont use the filter
        if obj.Config.use_spatial_footprint_filter == 1
%             % FixMe! Only used by the miniscope
%             sfplist = session.getCellSpatialFootprints(iCell);
%             sfpstats = struct('C1', [], 'C2', [], 'circularity', [], 'numComponents', [], 'occupiedArea', [], 'size', []);
%             for i = 1:length(sfplist)
%                 sfpstats(i) = ml_cai_spatialfootprint_stats(sfplist(i).spatial_footprint);
%             end
%             badi = union(find([sfpstats.circularity] > 1 | [sfpstats.circularity] < 0.4), find([sfpstats.size] < 10 | [sfpstats.size] > 20));
%             badi = union(badi, find([sfpstats.numComponents] > 1));
%             sfpValid = ~ismember(1:length(sfplist), badi);
            for iPM = 1:length(pmlist)
               sfpValid(iPM) = use_cell_per_trial{pmlist(iPM).trial_id}(pmlist(iPM).cell_id);
            end
              
        end
        
        %weightMatrix = session.getCellWeightMatrix(iCell);

        for iMap1 = 1:length(pmlist)
            if ~sfpValid(iMap1)
                continue;
            end
            
            x1 = pmlist(iMap1);
            
            if sum(x1.placemap, 'all') == 0
                continue;
            end


            % Only compare maps that actually have spikes
%             if x1.mltetrodeplacemap.totalSpikesAfterCriteria == 0
%                 continue;
%             end

            % Get the context
            context1 = x1.context_id;

            T1 = x1.placemap;
            %T1 = T1 ./ sum(T1, 'all');

            W1 = ones(size(T1));
            %W1(isnan(T1)) = 0;
            
            if mirrorContexts(context1) == 1
                T1 = fliplr(T1);
                W1 = fliplr(W1);
            end

            for iMap2 = 1:length(pmlist)
                
                if iMap1 == iMap2
                    continue;
                end
                
                if ~sfpValid(iMap2)
                    continue;
                end
                
                x2 = pmlist(iMap2);
                
                if sum(x2.placemap, 'all') == 0
                    continue;
                end
                                            % Only compare maps that actually have spikes
%                 if x2.mltetrodeplacemap.totalSpikesAfterCriteria == 0
%                     continue;
%                 end

                % Get the context
                context2 = x2.context_id;

                % Only compare trials that we actually want
                % to use, as some are redos or not used
                % due to experimental problems.
                if x1.trial_use ~= 1 || x2.trial_use ~= 1
                    continue;
                end

                T2 = x2.placemap;
                %T2 = T2 ./ sum(T2, 'all');

                W2 = ones(size(T2));
                %W2(isnan(T2)) = 0;

                if mirrorContexts(context2) == 1
                    T2 = fliplr(T2);
                    W2 = fliplr(W2);
                end

                fprintf('Computing within-context pixel-pixel cross-correlation (%d) for cell %s between trial %d and trial %d\n', rotDeg, perCell(iCell).cell_name, iMap1, iMap2);

                if rotDeg == 90
                    [vn, vindn] = ml_core_max_pixel_rotated_pixel_cross_correlation_90deg(T1, T2, 'W1',W1,'W2',W2);
                elseif rotDeg == 180
                    [vn, vindn] = ml_core_max_pixel_rotated_pixel_cross_correlation_180deg(T1, T2, 'W1',W1,'W2',W2);
                else
                    % this should be impossible
                    error('Logic error!');
                end
                
                % vindn may have more than one value
                
                if any(isnan(vn)) || any(isnan(vindn))
                    error('Nan should be impossible!');
                end
                
                
                % HACK TO CHECK
                vindn = vindn(randi(length(vindn)));
                
                % modify the correlation by the weight
                %vn = vn * weightMatrix(x1.trial_id, x2.trial_id);
                
                % Now store the result in the appropriate locations
                if context1 == context2
                    for iR = 1:length(vindn)
                        perCell(iCell).v_same(end+1) = vn;
                        perCell(iCell).vind_same(end+1) = vindn(iR);
                    end
                    
                    % Assign it to the correct context. First grap what we
                    % already have stored.
                    tmp_v = perCell(iCell).(sprintf('v_context%d', context1));
                    tmp_vind = perCell(iCell).(sprintf('vind_context%d', context1));
        
                    for iR = 1:length(vindn)
                        % Add the new entry
                        tmp_v(end+1) = vn;
                        tmp_vind(end+1) = vindn(iR);
                    end
                    
                    % Store the old and new
                    perCell(iCell).(sprintf('v_context%d', context1)) = tmp_v;
                    perCell(iCell).(sprintf('vind_context%d', context1)) = tmp_vind;

                end
                
                if context1 ~= context2
                    for iR = 1:length(vindn)
                        perCell(iCell).v_different(end+1) = vn;
                        perCell(iCell).vind_different(end+1) = vindn(iR);
                    end
                end
                
                for iR = 1:length(vindn)
                    perCell(iCell).v_all(end+1) = vn;
                    perCell(iCell).vind_all(end+1) = vindn(iR);
                end
                
            end % iMap2
        end % iMap1
        
        % Compute the averages and probability
        perCell(iCell).prob_same = histcounts( perCell(iCell).vind_same, 1:(numAngles+1), 'normalization', 'probability');
        perCell(iCell).avg_corr_same = mean(perCell(iCell).v_same);
        
        perCell(iCell).prob_different = histcounts( perCell(iCell).vind_different, 1:(numAngles+1), 'normalization', 'probability');
        perCell(iCell).avg_corr_different = mean(perCell(iCell).v_different);
        
        perCell(iCell).prob_all = histcounts( perCell(iCell).vind_all, 1:(numAngles+1), 'normalization', 'probability');
        perCell(iCell).avg_corr_all = mean(perCell(iCell).v_all);
        
        for iContext = 1:numContexts
            perCell(iCell).(sprintf('prob_context%d', iContext)) = histcounts( perCell(iCell).(sprintf('vind_context%d', iContext)), 1:(numAngles+1), 'normalization', 'probability');
            perCell(iCell).(sprintf('avg_corr_context%d', iContext)) = mean(perCell(iCell).(sprintf('v_context%d', iContext)));
        end
    end % iCell
    
    % Combine the per cell data
    total = {};
    
    blah = {'same', 'different', 'all'};
    for iContext = 1:numContexts
        blah{end+1} = sprintf('context%d', iContext);
    end
    
    for iB = 1:length(blah)
        blahType = blah{iB};
        counts = zeros(1, numAngles);
        for iCell = 1:numCells
            vind = perCell(iCell).(sprintf('vind_%s', blahType));
            %v = perCell(iCell).(sprintf('v_%s', blahType));
            s = histcounts(vind, 1:(numAngles+1));
            maxc = max(s);
            maxi = find(s == maxc);
            
            % It should be done this way
%             for iR = 1:length(maxi)
%                 counts( maxi(iR) ) = counts( maxi(iR) ) + 1;
%                 corr = [corr, v(maxi(iR))];
%             end
            
            j = randi(length(maxi));
            counts( maxi(j) ) = counts( maxi(j) ) + 1;
        end
        prob = counts ./ sum(counts, 'all') * 100;
        
        total.(sprintf('counts_%s', blahType)) = counts;
        total.(sprintf('prob_%s', blahType)) = prob;
    end % blah
        
end % function