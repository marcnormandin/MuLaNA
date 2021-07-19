function mltp_plot_rate_difference_matrices(obj, session)

mltp_plot_rate_difference_matrices_helper(obj, session, 'peakFiringRate', 'PFRS', false)
mltp_plot_rate_difference_matrices_helper(obj, session, 'meanFiringRate', 'MFR', true)
mltp_plot_rate_difference_matrices_helper(obj, session, 'informationRate', 'IC', false)
mltp_plot_rate_difference_matrices_helper(obj, session, 'informationPerSpike', 'IPS', false)

mltp_plot_rate_difference_matrices_helper(obj, session, 'peakFiringRateSmoothed', 'PFRS', false)
mltp_plot_rate_difference_matrices_helper(obj, session, 'meanFiringRateSmoothed', 'MFR', true)
mltp_plot_rate_difference_matrices_helper(obj, session, 'informationRateSmoothed', 'IC', false)
mltp_plot_rate_difference_matrices_helper(obj, session, 'informationPerSpikeSmoothed', 'IPS', false)

end
    
function mltp_plot_rate_difference_matrices_helper(obj, session, pfStatsField, figureField, saveMat)
    sessionName = session.getName();

    % Controls what values will be used
    % available fields:
    % meanFiringRate, peakFiringRate, informationRate, informationPerSpike
    %pfStatsField = 'peakFiringRate';
    %figureField = 'PFR';
    
    % Load the pfStats file that contains all of the information we
    % need.
    tfolder = session.getAnalysisDirectory(); %fullfile(pwd, 'analysis','chengs_task_2c', sessionName);
    pfStatsFilename = fullfile(tfolder, 'pfStats.mat');
    if ~isfile(pfStatsFilename)
        fprintf('Skipping session (%s) because (%s) not found.\n', sessionName, pfStatsFilename);
        return;
    end
    pfStats = load(pfStatsFilename);
    pfStats = pfStats.pfStats;
    
    fprintf('Processing session: %s for %s\n', sessionName, pfStatsField);

    % Get the number of trials to process because that is all that the
    % pfStats contains. It doesn't contain any data from trials not
    % processed.
    % Updated. Find the maximum trial id because the pfStats will have that
    % many rows
    maxTrialId = -1;
    for iTrial = 1:session.getNumTrials()
        trial = session.getTrialByOrder(iTrial);
        if trial.getTrialId() > maxTrialId
            maxTrialId = trial.getTrialId();
        end
    end
    
    if maxTrialId ~= length(pfStats(1).meanFiringRate)
        error("The session's maximum trial id (%d) and the length of the rows in pfStats (%d) do not match, but they should!", ...
            maxTrialId, size(pfStats,2));
    end
    
    numCells = length(pfStats); % or use the session itself
        
    % Cells are the rows and columns are the trials. Load the mean
    % firing rate for each cell.
    MFRT = zeros(numCells, maxTrialId);
    for iCell = 1:numCells
        rate = pfStats(iCell).(pfStatsField); %some firingRate;
        %rate(isnan(rate)) = nan;
        rate(isinf(rate)) = nan;
        rate(rate == 0) = nan;
        MFRT(iCell, :) = rate;
    end
    % The mean firing rate is NAN if there were no spikes so set it to zero
    MFRT(isnan(MFRT)) = 0;


    
    DALL = cell(numCells,1);
    DAVG = zeros(maxTrialId, maxTrialId); % store to average
    for iCell = 1:numCells
        D = zeros(maxTrialId, maxTrialId);
        for iTrial1 = 1:maxTrialId
            for iTrial2 = 1:maxTrialId
                % Calculate the absolute difference
                if ~isnan(MFRT(iCell, iTrial1)) && ~isnan(MFRT(iCell, iTrial2))
                    D(iTrial1, iTrial2) = abs( MFRT(iCell, iTrial1) - MFRT(iCell, iTrial2) );
                else
                    D(iTrial1, iTrial2) = nan;
                end
            end
        end        
        DALL{iCell} = D;
        DAVG = DAVG + D;
    end % iCell
    DAVG = DAVG ./ numCells; % compute the average over the cells
    
    % Sort based on context. We find indices grouped by context
    %contexts = []; % We do this to not assume that the context ids are 1,2,3, and allow them to be 1,32,55, etc.
    contexts = pfStats(1).context_id; % Every cell will have the same contexts so just index the first cell
%     for iTrial = 1:maxTrialId
%         %trial = session.getTrialToUse(iTrialToUse);
%         %contexts(end+1) = trial.getContextId();
%         contexts(end+1) = pfStats(1).(pfStatsField)
%     end
    contexts = sort(unique(contexts));
    numContexts = length(contexts);
    % Check for any possible bug
    if numContexts ~= obj.Experiment.getNumContexts()
        error('The number of contexts does not match, but they should!');
    end
    
    % We want an array of trials to use sorted by context
    tids = [];
    cids = [];
    for iContext = 1:numContexts
        for iTrial = 1:maxTrialId
            %trial = session.getTrialToUse(iTrialToUse);
            
            if pfStats(1).context_id(iTrial) == contexts(iContext)
                tids(end+1) = pfStats(1).trial_id(iTrial);
                cids(end+1) = pfStats(1).context_id(iTrial);
            end
        end
    end
    % Sort the matrices by context (rows and columns have to be switched)
    for iCell = 1:numCells
        x = DALL{iCell};
        x = x(tids,:);
        x = x(:, tids);
        DALL{iCell} = x; % added
    end
    DAVG = DAVG(tids,:);
    DAVG = DAVG(:, tids);
    
    %seqNum = [ti.sequenceNum];
    % This is for labeling the axes. We use the sequence numbers
    % become some actual trials may have been redone/not used.
%     seqNum = [];
%     for iTrialToUse = 1:session.getNumTrialsToUse()
%         trial = session.getTrialToUse(iTrialToUse);
%         seqNum(end+1) = trial.getSequenceId();
%     end
    seqNum = pfStats(1).trial_id;
    
    % Now sort them by the contexts
    seqNum = seqNum(tids); % get the sequences like 1,3,5,...
    labels = cell(1, maxTrialId);
    % THIS is the old way
%     for iTrial = 1:maxTrialId
%         labels{iTrial} = num2str(seqNum(iTrial));
%     end
    % This is the new and improved way.
    for iLabel = 1:length(cids)
       labels{iLabel} = sprintf('C%dT%dS%d', cids(iLabel), sum(cids(1:iLabel)==cids(iLabel)), seqNum(iLabel));
    end
            
    
    % Plotting
    hpercell = figure('name', sprintf('%s: %s (%s)', obj.Experiment.getAnimalName(), sessionName, figureField), 'Position', get(0,'Screensize'));
    %p = 3; q=ceil(numCells/3); k=1; % maximum of 25 cells on a plot
    cellNames = session.getTFilesFilenamePrefixes();
    for iCell = 1:numCells
        cellName = cellNames{iCell};
        
        clf(hpercell, 'reset');

            
        %
        %subplot(p,q,k);
        %k = k + 1;
        DP = DALL{iCell};
        [nr,nc] = size(DP);
        matrixToPlot = [DP, nan(nr,1); nan(1,nc+1)];
        for i = 1:size(matrixToPlot,1)
            matrixToPlot(i,i) = nan;
        end
        pcolor( matrixToPlot );
        shading flat;
        set(gca, 'ydir', 'reverse');
            
        %imagesc(DALL{iCell})
        colormap jet
        xticks(1.5:(maxTrialId+0.5))
        xticklabels(labels);
        xtickangle(90);
        yticks(1.5:(maxTrialId+0.5))
        yticklabels(labels);
        %title(sprintf('Cell %d', iCell));
        title(sprintf('%s', cellName), 'interpreter', 'none');
        
        axis equal square tight
        hold on;
        
        % Plot a outlined rectangle around each context with itself
        for iContext = 1:numContexts
            nb = sum( cids < contexts(iContext) ) + 1;
            ne = sum( cids == contexts(iContext) );
            
            
            rectangle('Position',[nb,nb,ne,ne],...
                      'Curvature',[0,0],...
                     'LineWidth',4,'LineStyle','-')
        end
%         rectangle('Position',[6.5,6.5,6,6],...
%                   'Curvature',[0,0],...
%                  'LineWidth',4,'LineStyle','-')
        colorbar
        
        
        % Save the plots
        outputFolder = fullfile(tfolder, obj.Config.rate_difference_matrices.outputFolder, 'per_cell');
        if ~exist(outputFolder,'dir')
            mkdir(outputFolder)
        end

        F = getframe(hpercell);
        imwrite(F.cdata, fullfile(outputFolder, sprintf('%s_%s_difference_matrix.png', cellName, pfStatsField)), 'png')
        savefig(hpercell, fullfile(outputFolder, sprintf('%s_%s_difference_matrix.fig', cellName, pfStatsField)));
        
    
    end
    close(hpercell);




    % AVERAGE MATRIX
    outputFolder = fullfile(tfolder, obj.Config.rate_difference_matrices.outputFolder);
    if ~exist(outputFolder,'dir')
        mkdir(outputFolder)
    end

    havg = figure('name', sprintf('%s: %s', obj.Experiment.getAnimalName(), sessionName));
    %imagesc(DAVG)
    [nr,nc] = size(DAVG);
    %pcolor( [DAVG, nan(nr,1); nan(1,nc+1)] );
    matrixToPlot = [DAVG, nan(nr,1); nan(1,nc+1)];
    for i = 1:size(matrixToPlot,1)
        matrixToPlot(i,i) = nan;
    end
    pcolor( matrixToPlot );
        
    shading flat;
    set(gca, 'ydir', 'reverse');
        
    colormap jet
    xticks(1.5:(maxTrialId+0.5))
    xticklabels(labels);
    xtickangle(45);
    yticks(1.5:(maxTrialId+0.5))
    yticklabels(labels);
    title(sprintf('AVERAGE ACROSS CELLS\n(%s: %s)', obj.Experiment.getAnimalName(), sessionName), 'interpreter', 'none')
    hold on;
    for iContext = 1:numContexts
        nb = sum( cids < contexts(iContext) ) + 1;
        ne = sum( cids == contexts(iContext) );


        rectangle('Position',[nb,nb,ne,ne],...
                  'Curvature',[0,0],...
                 'LineWidth',4,'LineStyle','-')
    end
    hcb = colorbar;
    title(hcb, 'Rate Difference');

    F = getframe(havg);
    imwrite(F.cdata, fullfile(outputFolder, sprintf('averaged_%s_difference_matrix.png', pfStatsField)), 'png')
    savefig(havg, fullfile(outputFolder, sprintf('averaged_%s_difference_matrix.fig', pfStatsField)));
    close(havg);
    
    
    
    % Save the data for averaging over days
    if saveMat
        rate_difference_matrices_per_cell = DALL;
        rate_difference_matrix_average = DAVG;
        save(fullfile(outputFolder, obj.Config.rate_difference_matrices.outputMatFilename), 'rate_difference_matrices_per_cell', 'rate_difference_matrix_average', 'maxTrialId', 'labels', 'seqNum', 'tids', 'cids');
    end
end % function
