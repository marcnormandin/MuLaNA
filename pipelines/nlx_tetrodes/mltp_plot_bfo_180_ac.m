function mltp_plot_bfo_180_ac(obj)
    numAngles = 2;
    best_fit_orientations_all_contexts = zeros(obj.Experiment.getNumSessions(), numAngles);
    plotlegend = cell(obj.Experiment.getNumSessions(), 1);
    for iSession = 1:obj.Experiment.getNumSessions()
        session = obj.Experiment.getSession(iSession);
        dataFolder = fullfile(session.getAnalysisDirectory(), obj.Config.best_fit_orientations.outputFolder);
        
        tmp = load(fullfile(dataFolder,'bfo_180_ac.mat'));        
        
        % Use only those angles whose result was not zero
        nonZeroIndices = find(tmp.v > 0);
        x = tmp.vind(nonZeroIndices);
        if ~isempty(x)
            best_fit_orientations_all_contexts(iSession,:) = histcounts(x, 1:numAngles+1); %histcounts(tmp.vind(:));
            best_fit_orientations_all_contexts(iSession,:) = best_fit_orientations_all_contexts(iSession,:) ./ sum(best_fit_orientations_all_contexts(iSession,:));
        else
            best_fit_orientations_all_contexts(iSession,:) = 0*ones(1,numAngles);
        end
        plotlegend{iSession} = session.getName();
    end
    % All of the sessions
    h = figure('Name', sprintf('Best Fit Orientations (all contexts) ( %s )', obj.Experiment.getAnimalName()), 'Position', get(0,'Screensize'));
    bar([0, 180], best_fit_orientations_all_contexts');
    hold on 
    grid on
    title(sprintf('Best Fit Orientations (all contexts) ( %s )', obj.Experiment.getAnimalName()), 'Interpreter', 'none')
    ylabel('Proportion Best Fit')
    xticklabels({['0' char(176)], ['180' char(176)]});
    legend(plotlegend)
    outputFolder = obj.Experiment.getAnalysisParentDirectory();
    F = getframe(h);
    imwrite(F.cdata, fullfile(outputFolder, 'bfo_180_ac.png'), 'png')
    savefig(h, fullfile(outputFolder, 'bfo_180_ac.fig'));
    saveas(h, fullfile(outputFolder, 'bfo_180_ac.svg'), 'svg');
    print('-painters', '-depsc', fullfile(outputFolder,'bfo_180_ac.eps'))
    close(h);
    save(fullfile(outputFolder, 'bfo_180_ac.mat'), 'best_fit_orientations_all_contexts');

end % function