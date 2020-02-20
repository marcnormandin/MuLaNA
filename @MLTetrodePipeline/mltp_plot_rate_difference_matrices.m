function mltp_plot_rate_difference_matrices(obj)
    for iSession = 1:obj.experiment.numSessions
        sessionName = obj.experiment.session{iSession}.name;

        tfolder = obj.experiment.session{iSession}.analysisFolder; %fullfile(pwd, 'analysis','chengs_task_2c', sessionName);
        %x = readtable(fullfile(tfolder, 'pfStats.xlsx'));
        pfStatsFilename = fullfile(tfolder, 'pfStats.xlsx');
        if ~isfile(pfStatsFilename)
            fprintf('Skipping session (%s) because pfStats.xlsx not found.\n', sessionName);
            continue;
        end

        fprintf('Processing session: %s\n', sessionName);

        x = xlsread(pfStatsFilename, sprintf('%s_meanFiringRate', sessionName));
        %x = xlsread(fullfile(tfolder, 'pfStats.xlsx'), sprintf('%s_informationPerSpike', sessionName));

        MFRT = x(2:end, 2:end);
        numTrials = size(MFRT,1);
        numCells = size(MFRT,2);
        MFRT = MFRT';
        % Cells are the rows and columns are the trials

        DALL = {};
        DAVG = zeros(numTrials, numTrials);
        hpercell = figure('name', sprintf('%s: %s', obj.experiment.subjectName, sessionName), 'Position', get(0,'Screensize'));
        p=5; q=5; k=1;
        for iCell = 1:numCells
            D = zeros(numTrials, numTrials);
            for iTrial1 = 1:numTrials
                for iTrial2 = 1:numTrials
                    tmap = [1:2:numTrials, 2:2:numTrials];
                    D(iTrial1, iTrial2) = abs( MFRT(iCell, tmap(iTrial1)) - MFRT(iCell, tmap(iTrial2)) );
                end
            end        
            DALL{iCell} = D;
            DAVG = DAVG + D;

            %
            subplot(p,q,k);
            k = k + 1;
            imagesc(D)
            colormap jet
            xticks(1:12)
            xticklabels({'1','3','5','7','9','11','2','4','6','8','10','12'});
            yticks(1:12)
            yticklabels({'1','3','5','7','9','11','2','4','6','8','10','12'});
            title(sprintf('Cell %d', iCell));
            axis equal square
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
        outputFolder = fullfile(tfolder, 'rate_difference_matrices');
        if ~exist(outputFolder,'dir')
            mkdir(outputFolder)
        end

        F = getframe(hpercell);
        imwrite(F.cdata, fullfile(outputFolder, sprintf('rate_difference_matrix_per_cell.png')), 'png')
        savefig(hpercell, fullfile(outputFolder, sprintf('rate_difference_matrix_per_cell.fig')));
        close(hpercell);



        DAVG = DAVG ./ numCells;

        havg = figure('name', sprintf('%s: %s', obj.experiment.subjectName, sessionName));
        imagesc(DAVG)
        colormap jet
        xticks(1:12)
        xticklabels({'1','3','5','7','9','11','2','4','6','8','10','12'});
        yticks(1:12)
        yticklabels({'1','3','5','7','9','11','2','4','6','8','10','12'});
        title(sprintf('AVERAGE ACROSS CELLS (%s: %s)', obj.experiment.subjectName, sessionName))
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
    end 

end