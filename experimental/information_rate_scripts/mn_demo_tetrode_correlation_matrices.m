close all
clear all
clc

pipeCfgFilename = fullfile(pwd, 'pipeline_config.json');

%subjects = {'MG1_DH', 'K1', 'AK42', 'AK74', 'JJ9'};
subjects = {'MG1_DH', 'K1', 'AK42','AK74', 'JJ9'};


for iSubject = 1:length(subjects)
    subjectName = subjects{iSubject};
    recordingsParentFolder = fullfile(pwd, subjectName, 'recordings', 'chengs_task_2c');
    analysisParentFolder = fullfile(pwd, subjectName, 'analysis', 'chengs_task_2c');

    pipe = MLTetrodePipeline( pipeCfgFilename, recordingsParentFolder, analysisParentFolder);

    %sessionNames = {'s7', 's8', 's9', 's10', 's11'};
    for iSession = 1:pipe.experiment.numSessions
        sessionName = pipe.experiment.session{iSession}.name;

        tfolder = pipe.experiment.session{iSession}.analysisFolder; %fullfile(pwd, 'analysis','chengs_task_2c', sessionName);
        %x = readtable(fullfile(tfolder, 'pfStats.xlsx'));
        pfStatsFilename = fullfile(tfolder, 'pfStats.xlsx')
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
        h = figure('name', sprintf('%s: %s', pipe.experiment.subjectName, sessionName), 'Position', get(0,'Screensize'));
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
        DAVG = DAVG ./ numCells;

        havg = figure('name', sprintf('%s: %s', pipe.experiment.subjectName, sessionName));
        imagesc(DAVG)
        colormap jet
        xticks(1:12)
        xticklabels({'1','3','5','7','9','11','2','4','6','8','10','12'});
        yticks(1:12)
        yticklabels({'1','3','5','7','9','11','2','4','6','8','10','12'});
        %title(sprintf('AVERAGE ACROSS CELLS (%s)', sessionName), 'Position', get(0,'Screensize'))
        hold on;
        rectangle('Position',[0.5,0.5,6,6],...
                  'Curvature',[0,0],...
                 'LineWidth',4,'LineStyle','-')
        rectangle('Position',[6.5,6.5,6,6],...
                  'Curvature',[0,0],...
                 'LineWidth',4,'LineStyle','-')
        hcb = colorbar;
        title(hcb, 'Rate Difference');

        % Save the plots
    %     F = getframe(h);
    %     imwrite(F.cdata, fullfile(sprintf('%s_rate_difference_per_cell.png',sessionName, iCell)), 'png')
    %     savefig(h, fullfile(sprintf('%s_rate_difference_per_cell.fig', sessionName, iCell)));
    %     close(h);
    end

end

