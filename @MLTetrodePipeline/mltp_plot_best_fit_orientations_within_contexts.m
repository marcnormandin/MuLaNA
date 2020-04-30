function mltp_plot_best_fit_orientations_within_contexts(obj)    
    numAngles = 4;
    best_fit_orientations_within_contexts = zeros(obj.experiment.numSessions, numAngles);
    plotlegend = cell(obj.experiment.numSessions, 1);
    for iSession = 1:obj.experiment.numSessions
        session = obj.experiment.session{iSession};
        tmp = load(fullfile(session.analysisFolder, obj.config.canon_square_placemaps_folder,'best_fit_orientations_within_contexts.mat'));
        % Use only those angles whose result was not zero
        nonZeroIndices = find(tmp.v > 0);
        x = tmp.vind(nonZeroIndices);
        if ~isempty(x)
            best_fit_orientations_within_contexts(iSession,:) = histcounts(x, 1:numAngles+1); %histcounts(tmp.vind(:));
            best_fit_orientations_within_contexts(iSession,:) = best_fit_orientations_within_contexts(iSession,:) ./ sum(best_fit_orientations_within_contexts(iSession,:));
        else
            best_fit_orientations_within_contexts(iSession,:) = 0*ones(1,4);
        end
        plotlegend{iSession} = session.record.session_info.name;
    end
    % All of the sessions
    h = figure('Name', sprintf('Best Fit Orientations (within contexts) ( %s )', obj.experiment.subjectName), 'Position', get(0,'Screensize'));
    bar([0, 90, 180, 270], best_fit_orientations_within_contexts');
    hold on 
    grid on
    title(sprintf('Best Fit Orientations (within contexts) ( %s )', obj.experiment.subjectName), 'Interpreter', 'none')
    ylabel('Proportion Best Fit')
    xticklabels({['0' char(176)], ['90' char(176)], ['180' char(176)], ['270' char(176)]});
    legend(plotlegend)
    outputFolder = obj.analysisParentFolder;
    F = getframe(h);
    imwrite(F.cdata, fullfile(outputFolder, 'best_fit_orientations_within_contexts.png'), 'png')
    savefig(h, fullfile(outputFolder, 'best_fit_orientations_within_contexts.fig'));
    saveas(h, fullfile(outputFolder, 'best_fit_orientations_within_contexts.svg'), 'svg');
    print('-painters', '-depsc', fullfile(outputFolder,'best_fit_orientations_within_contexts.eps'))
    close(h);
    save(fullfile(outputFolder, 'best_fit_orientations_within_contexts.mat'), 'best_fit_orientations_within_contexts');

end % function