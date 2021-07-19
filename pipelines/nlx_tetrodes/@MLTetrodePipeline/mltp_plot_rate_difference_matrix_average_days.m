function mltp_plot_rate_difference_matrix_average_days(obj)
    averageMatrix = {};
    seqNum = [];
    cids = [];
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
            fprintf('Skipping session (%s) because (%s) not found.\n', sessionName, dataFilename);
            return;
        end
        data = load(dataFilename);
        
        % If it is the first one loaded, then just store it
        if isempty(averageMatrix)
            averageMatrix = data.rate_difference_matrix_average;
            maxTrialId = data.maxTrialId;
            seqNum = data.seqNum;
            %labels = data.labels;
            % See the larger note below, we can't use actual trial numbers
            % because different contexts can begin each session and so that
            % is meaningless.
            cids = data.cids;
            for iLabel = 1:length(cids)
               labels{iLabel} = sprintf('C%dT%d', cids(iLabel), sum(cids(1:iLabel)==cids(iLabel)));
            end
        else
            % Check that combining makes sense
            if length(cids) ~= length(data.cids)
                fprintf('Cannot average because the matrices have different dimensions (trials)\n');
                return;
            end
            
            % NOTE: Depending on what is the very first context, the
            % sequences will end up as either of these two
            % A) 1 3 5 7 9 11 2 4 6 8 10 12 <-- context 1, then context 2
            % B) 2 4 6 8 10 12 1 3 5 7 9 11 <-- context 1, then context 2
            % context 1 trials always come before context 2, so when
            % averaging across sessions, all we need is for the number of
            % trials to be the same, and so this conditional isn't needed.
%             if ~all(seqNum == data.seqNum)
%                 fprintf('Cannot average because the sequence nums are different.');
%                 return
%             end
            % instead check that the context ids match
            if ~all(data.cids == cids)
                fprintf('Cannot average the ratemaps because the matrices are not in the same order.\n');
            end
            averageMatrix = averageMatrix + data.rate_difference_matrix_average;
        end
    end % iSession
    averageMatrix = averageMatrix ./ numSessions;
    
    havg = figure('name', sprintf('%s', obj.Experiment.getAnimalName()));
        imagesc(averageMatrix)
        colormap jet
        xticks(1:maxTrialId)
        xticklabels(labels);
        xtickangle(45);
        yticks(1:maxTrialId)
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
        
        F = getframe(havg);
        imwrite(F.cdata, fullfile(outputFolder, sprintf('rate_difference_matrix_avg_across_days.png')), 'png')
        savefig(havg, fullfile(outputFolder, sprintf('rate_difference_matrix_avg_across_days.fig')));
        close(havg);        
end % function
