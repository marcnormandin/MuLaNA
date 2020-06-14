function mltp_compute_rate_difference_averages(obj)
    seqNum = [];
    labels = {};
    numSessions = obj.Experiment.getNumSessions();
    for iSession = 1:numSessions
        session = obj.Experiment.getSession(iSession);
        sessionName = session.getName();

        % Load the pfStats file that contains all of the information we
        % need.
        tfolder = session.getAnalysisDirectory(); %fullfile(pwd, 'analysis','chengs_task_2c', sessionName);
        dataFilename = fullfile(tfolder, ...
            obj.Config.rate_difference_matrices.outputFolder, ...
            obj.Config.rate_difference_matrices.outputMatFilename);
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
            if length(seqNum) ~= length(data.seqNum)
                fprintf('Cannot average because the matrices have different dimensions (trials)\n');
                return;
            end
            
            if ~all(seqNum == data.seqNum)
                fprintf('Cannot average because the sequence nums are different.');
                return
            end
            averageMatrix = averageMatrix + data.rate_difference_matrix_average;
        end
    end % iSession
    averageMatrix = averageMatrix ./ numSessions;
    
    havg = figure('name', sprintf('%s', obj.Experiment.getAnimalName()));
        imagesc(averageMatrix)
        colormap jet
        xticks(1:numTrials)
        xticklabels(labels);
        yticks(1:numTrials)
        yticklabels(labels);
        title(sprintf('%s\nAVERAGE ACROSS (%d) DAYS', obj.Experiment.getAnimalName(), numSessions), 'interpreter', 'none')
        hold on;
        rectangle('Position',[0.5,0.5,6,6],...
                  'Curvature',[0,0],...
                 'LineWidth',4,'LineStyle','-')
        rectangle('Position',[6.5,6.5,6,6],...
                  'Curvature',[0,0],...
                 'LineWidth',4,'LineStyle','-')
        hcb = colorbar;
        title(hcb, 'Rate Difference');

        outputFolder = obj.Experiment.getAnalysisParentDirectory();
        
        save(fullfile(outputFolder, 'rate_difference_average_matrix.mat'), 'averageMatrix');
        
        F = getframe(havg);
        imwrite(F.cdata, fullfile(outputFolder, sprintf('rate_difference_matrix_avg_across_days.png')), 'png')
        savefig(havg, fullfile(outputFolder, sprintf('rate_difference_matrix_avg_across_days.fig')));
        close(havg);        
end % function
