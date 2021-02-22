function mltp_plot_best_match_rotations_rect_per_session(obj)

    bfo_dist = [];
    sessionNames = {};
    for iSession = 1:obj.Experiment.getNumSessions()
        session = obj.Experiment.getSession(iSession);
        tmp = load(fullfile(session.getAnalysisDirectory(), 'best_match_rotations', 'best_match_rotations.mat'));
        bfo_dist(iSession,:) = tmp.best_match_rotations.bfo_dist;
        sessionNames{iSession} = session.getName();
    end

    h = figure();
    bar(bfo_dist')
    legend(sessionNames)
    grid on
    grid minor
    set(gca,'XTickLabel',{['0' char(176)], ['90' char(176)], ['180' char(176)], ['270' char(176)]})
    %xlabel('Orientation [deg]')
    ylabel('Proportion Best Fit', 'fontweight', 'bold')
    title(sprintf('Best Fit Orientations: %s', obj.Experiment.getAnimalName()), 'interpreter', 'none')

    % Save the figure
    outputFolder = obj.Experiment.getAnalysisParentDirectory();
    F = getframe(h);
    fnPrefix = 'best_match_rotations_per_session';
    imwrite(F.cdata, fullfile(outputFolder, sprintf('%s.png', fnPrefix)), 'png')
    savefig(h, fullfile(outputFolder, sprintf('%s.fig', fnPrefix)));
    saveas(h, fullfile(outputFolder, sprintf('%s.svg', fnPrefix)), 'svg');
    print('-painters', '-depsc', fullfile(outputFolder,sprintf('%s.eps', fnPrefix)))
    close(h);

end % function