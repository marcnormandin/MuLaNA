function mltp_plot_rate_difference_matrix_average_days(obj)
    averageMatrix = {};
    seqNum = [];
    labels = {};
    numSessions = obj.experiment.numSessions;
    for iSession = 1:numSessions
        session = obj.experiment.session{iSession};
        sessionName = session.name;

        % Load the pfStats file that contains all of the information we
        % need.
        tfolder = session.analysisFolder; %fullfile(pwd, 'analysis','chengs_task_2c', sessionName);
        dataFilename = fullfile(tfolder, ...
            obj.config.rate_difference_matrices.outputFolder, ...
            obj.config.rate_difference_matrices.outputMatFilename);
        if ~isfile(dataFilename)
            fprintf('Skipping session (%s) because (%s) found.\n', sessionName, dataFilename);
            return;
        end
        data = load(dataFilename);
        
        % If it is the first one loaded, then just store it
        if isempty(averageMatrix)
            averageMatrix = data.rate_difference_matrix_average;
            numTrials = data.numTrials;
            seqNum = data.seqNum;
            labels = data.labels;
        else
            % Check that combining makes sense
            if ~all(seqNum == data.seqNum)
                fprintf('Cannot average because the sequence nums are different.');
                return
            end
            averageMatrix = averageMatrix + data.rate_difference_matrix_average;
        end
    end % iSession
    averageMatrix = averageMatrix ./ numSessions;
    
    havg = figure('name', sprintf('%s', obj.experiment.subjectName));
        imagesc(averageMatrix)
        colormap jet
        xticks(1:numTrials)
        xticklabels(labels);
        yticks(1:numTrials)
        yticklabels(labels);
        title(sprintf('%s\nAVERAGE ACROSS (%d) DAYS', obj.experiment.subjectName, numSessions), 'interpreter', 'none')
        hold on;
        rectangle('Position',[0.5,0.5,6,6],...
                  'Curvature',[0,0],...
                 'LineWidth',4,'LineStyle','-')
        rectangle('Position',[6.5,6.5,6,6],...
                  'Curvature',[0,0],...
                 'LineWidth',4,'LineStyle','-')
        hcb = colorbar;
        title(hcb, 'Rate Difference');

        outputFolder = obj.analysisParentFolder;
        
        F = getframe(havg);
        imwrite(F.cdata, fullfile(outputFolder, sprintf('rate_difference_matrix_avg_across_days.png')), 'png')
        savefig(havg, fullfile(outputFolder, sprintf('rate_difference_matrix_avg_across_days.fig')));
        close(havg);        
end % function
