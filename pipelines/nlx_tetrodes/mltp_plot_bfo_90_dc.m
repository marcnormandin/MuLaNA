function mltp_plot_bfo_90_dc(obj)
    numAngles = 4;
    best_fit_orientations_different_contexts = zeros(obj.Experiment.getNumSessions(), numAngles);
    plotlegend = cell(obj.Experiment.getNumSessions(), 1);
    for iSession = 1:obj.Experiment.getNumSessions()
        session = obj.Experiment.getSession(iSession);
        
        % We have to use the shrunk data if the shape is a rectangle
        if strcmpi(obj.getArena().shape, 'rectangle')
            dataFolder = fullfile(session.getAnalysisDirectory(), obj.Config.placemaps.outputFolderShrunk);
        else
            dataFolder = fullfile(session.getAnalysisDirectory(), obj.Config.placemaps.outputFolder);
        end
        tmp = load(fullfile(dataFolder,'bfo_90_different.mat'));        
        
        % Use only those angles whose result was not zero
        nonZeroIndices = find(tmp.v > 0);
        x = tmp.vind(nonZeroIndices);
        if ~isempty(x)
            best_fit_orientations_different_contexts(iSession,:) = histcounts(x, 1:numAngles+1); %histcounts(tmp.vind(:));
            best_fit_orientations_different_contexts(iSession,:) = best_fit_orientations_different_contexts(iSession,:) ./ sum(best_fit_orientations_different_contexts(iSession,:));
        else
            best_fit_orientations_different_contexts(iSession,:) = 0*ones(1,4);
        end
        plotlegend{iSession} = session.getName();
    end
    % All of the sessions
    h = figure('Name', sprintf('Best Fit Orientations (different contexts) ( %s )', obj.Experiment.getAnimalName()), 'Position', get(0,'Screensize'));
    bar([0, 90, 180, 270], best_fit_orientations_different_contexts');
    hold on 
    grid on
    title(sprintf('Best Fit Orientations (different contexts) ( %s )', obj.Experiment.getAnimalName()), 'Interpreter', 'none')
    ylabel('Proportion Best Fit')
    xticklabels({['0' char(176)], ['90' char(176)], ['180' char(176)], ['270' char(176)]});
    legend(plotlegend)
    outputFolder = obj.Experiment.getAnalysisParentDirectory();
    F = getframe(h);
    imwrite(F.cdata, fullfile(outputFolder, 'bfo_90_dc.png'), 'png')
    savefig(h, fullfile(outputFolder, 'bfo_90_dc.fig'));
    saveas(h, fullfile(outputFolder, 'bfo_90_dc.svg'), 'svg');
    print('-painters', '-depsc', fullfile(outputFolder,'bfo_90_dc.eps'))
    close(h);
    save(fullfile(outputFolder, 'best_fit_orientations_different_contexts.mat'), 'best_fit_orientations_different_contexts');

end % function