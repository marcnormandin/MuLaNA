function mltp_plot_rate_difference_matrices(obj, session)
    sessionName = session.name;

    % Load the pfStats file that contains all of the information we
    % need.
    tfolder = session.analysisFolder; %fullfile(pwd, 'analysis','chengs_task_2c', sessionName);
    pfStatsFilename = fullfile(tfolder, 'pfStats.mat');
    if ~isfile(pfStatsFilename)
        fprintf('Skipping session (%s) because (%s) found.\n', sessionName, pfStatsFilename);
        return;
    end
    pfStats = load(pfStatsFilename);
    pfStats = pfStats.pfStats;
    
    fprintf('Processing session: %s\n', sessionName);

    % Get the number of trials to process because that is all that the
    % pfStats contains. It doesn't contain any data from trials not
    % processed.
    sr = session.sessionRecord;
    ti = sr.getTrialsToProcess(); % for the contexts
    numTrials = sr.getNumTrialsToProcess();
    numCells = length(pfStats); % or use the session itself

    % Cells are the rows and columns are the trials. Load the mean
    % firing rate for each cell.
    MFRT = zeros(numCells, numTrials);
    for iCell = 1:numCells
        MFRT(iCell, :) = pfStats(iCell).meanFiringRate;
    end
    % The mean firing rate is NAN if there were no spikes so set it to zero
    MFRT(isnan(MFRT)) = 0;


    
    DALL = cell(numCells,1);
    DAVG = zeros(numTrials, numTrials); % store to average
    for iCell = 1:numCells
        D = zeros(numTrials, numTrials);
        for iTrial1 = 1:numTrials
            for iTrial2 = 1:numTrials
                D(iTrial1, iTrial2) = abs( MFRT(iCell, iTrial1) - MFRT(iCell, iTrial2) );
            end
        end        
        DALL{iCell} = D;
        DAVG = DAVG + D;
    end % iCell
    DAVG = DAVG ./ numCells; % compute the average over the cells
    
    % Sort based on context. We find indices grouped by context
    contexts = sort(unique([ti.context]));
    numContexts = length(contexts);
    tids = [];
    for iContext = 1:numContexts
        tids = [tids, find([ti.context] == contexts(iContext))];
    end
    % Sort the matrices by context (rows and columns have to be switched)
    for iCell = 1:numCells
        x = DALL{iCell};
        x = x(tids,:);
        x = x(:, tids);
    end
    DAVG = DAVG(tids,:);
    DAVG = DAVG(:, tids);
    
    seqNum = [ti.sequenceNum];
    seqNum = seqNum(tids); % get the sequences like 1,3,5,...
    labels = cell(1, numTrials);
    for iTrial = 1:numTrials
        labels{iTrial} = num2str(seqNum(iTrial));
    end
    
    % Plotting
    hpercell = figure('name', sprintf('%s: %s', obj.experiment.subjectName, sessionName), 'Position', get(0,'Screensize'));
    p = 3; q=ceil(numCells/3); k=1; % maximum of 25 cells on a plot
    for iCell = 1:numCells
        %
        subplot(p,q,k);
        k = k + 1;
        imagesc(DALL{iCell})
        colormap jet
        xticks(1:numTrials)
        xticklabels(labels);
        yticks(1:numTrials)
        yticklabels(labels);
        title(sprintf('Cell %d', iCell));
        axis equal square tight
        hold on;
        rectangle('Position',[0.5,0.5,6,6],...
                  'Curvature',[0,0],...
                 'LineWidth',4,'LineStyle','-')
        rectangle('Position',[6.5,6.5,6,6],...
                  'Curvature',[0,0],...
                 'LineWidth',4,'LineStyle','-')
        colorbar
    end

    % Save the plots
    outputFolder = fullfile(tfolder, obj.config.rate_difference_matrices.outputFolder);
    if ~exist(outputFolder,'dir')
        mkdir(outputFolder)
    end

    F = getframe(hpercell);
    imwrite(F.cdata, fullfile(outputFolder, sprintf('rate_difference_matrix_per_cell.png')), 'png')
    savefig(hpercell, fullfile(outputFolder, sprintf('rate_difference_matrix_per_cell.fig')));
    close(hpercell);




    havg = figure('name', sprintf('%s: %s', obj.experiment.subjectName, sessionName));
    imagesc(DAVG)
    colormap jet
    xticks(1:numTrials)
    xticklabels(labels);
    yticks(1:numTrials)
    yticklabels(labels);
    title(sprintf('AVERAGE ACROSS CELLS (%s: %s)', obj.experiment.subjectName, sessionName), 'interpreter', 'none')
    hold on;
    rectangle('Position',[0.5,0.5,6,6],...
              'Curvature',[0,0],...
             'LineWidth',4,'LineStyle','-')
    rectangle('Position',[6.5,6.5,6,6],...
              'Curvature',[0,0],...
             'LineWidth',4,'LineStyle','-')
    hcb = colorbar;
    title(hcb, 'Rate Difference');

    F = getframe(havg);
    imwrite(F.cdata, fullfile(outputFolder, sprintf('averaged_rate_difference_matrix.png')), 'png')
    savefig(havg, fullfile(outputFolder, sprintf('averaged_rate_difference_matrix.fig')));
    close(havg);
    
    
    
    % Save the data for averaging over days
    rate_difference_matrices_per_cell = DALL;
    rate_difference_matrix_average = DAVG;
    save(fullfile(outputFolder, obj.config.rate_difference_matrices.outputMatFilename), 'rate_difference_matrices_per_cell', 'rate_difference_matrix_average', 'numTrials', 'labels', 'seqNum');
    
end % function
