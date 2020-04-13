function mltp_plot_best_fit_orientations_averaged_across_sessions(obj)

    % Only applicable if experiment has more than one session
    if obj.experiment.numSessions < 2
        warning('plot_best_fit_orientations_averaged_across_sessions requires more than one session of data. Skipping.')
        return
    end
    
    tmp = load(fullfile(obj.analysisParentFolder, 'best_fit_orientations_all_contexts.mat'));
    x1 = tmp.best_fit_orientations_all_contexts;
    x1mean = mean(x1,1);
    x1std = std(x1,1);

    tmp = load(fullfile(obj.analysisParentFolder, 'best_fit_orientations_within_contexts.mat'));
    x2 = tmp.best_fit_orientations_within_contexts;
    x2mean = mean(x2,1);
    x2std = std(x2,1);

    xstd = [x1std; x2std]';
    xmean = [x1mean; x2mean]';

    h = figure;
    %bar([0, 90, 180, 270], [x1mean; x2mean]')
    %hold on
    y1 = xmean;
    %err1 = xstd;
    hBar = bar(y1,1);
    hBar(1).FaceColor = [0, 0, 0.5];
    hBar(1).FaceAlpha = 0.6;
    hBar(1).LineWidth = 2;
    hBar(2).FaceColor = [0, 0, 1.0];
    hBar(2).FaceAlpha = 0.4;
    hBar(2).LineWidth = 2;
    % Return �bar� Handle
    hold on
    for k1 = 1:size(y1,2)
        ctr(k1,:) = bsxfun(@plus, hBar(k1).XData, hBar(k1).XOffset');    % Note: �XOffset� Is An Undocumented Feature; This Selects The �bar� Centres
        ydt(k1,:) = hBar(k1).YData;% Individual Bar Heights
        err1(k1,:) = xstd(:,k1);
    end
    hold on
    errorbar(ctr, ydt, err1, 'k.', 'linewidth', 2) 
    legend({'all contexts', 'within contexts'});
    grid on
    grid minor
    set(gca,'XTickLabel',{['0' char(176)], ['90' char(176)], ['180' char(176)], ['270' char(176)]})
    %xlabel('Orientation [deg]')
    ylabel('Proportion Best Fit', 'fontweight', 'bold')
    title(sprintf('Best Fit Orientations: %s', obj.experiment.subjectName), 'interpreter', 'none')

    % Save the figure
    outputFolder = obj.analysisParentFolder;
    F = getframe(h);
    fnPrefix = 'best_fit_orientations_averaged_across_sessions';
    imwrite(F.cdata, fullfile(outputFolder, sprintf('%s.png', fnPrefix)), 'png')
    savefig(h, fullfile(outputFolder, sprintf('%s.fig', fnPrefix)));
    saveas(h, fullfile(outputFolder, sprintf('%s.svg', fnPrefix)), 'svg');
    print('-painters', '-depsc', fullfile(outputFolder,sprintf('%s.eps', fnPrefix)))
    close(h);

end % function