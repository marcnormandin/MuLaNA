function ml_two_contexts_plot_best_fit_alignment(projectConfig)
    plot_feature_rich_all_contexts(projectConfig);
    plot_feature_poor_all_contexts(projectConfig);
    plot_feature_rich_within_contexts(projectConfig);
    plot_feature_poor_within_contexts(projectConfig);
end % function

function plot_feature_rich_all_contexts(projectConfig)
    ss = 'best_fit_orientations_all_contexts';
    
    files = {...
        fullfile(projectConfig.analysisFolder, 'feature_rich', 'AK42_CA1', 'best_fit_orientations_all_contexts.mat'), ...
        fullfile(projectConfig.analysisFolder, 'feature_rich', 'AK74_CA1', 'best_fit_orientations_all_contexts.mat'), ...
        fullfile(projectConfig.analysisFolder, 'feature_rich', 'JJ9_CA1', 'best_fit_orientations_all_contexts.mat')};
    
    [day1mean, day1std] = get_mice_day_stats(files, [1,1,1], ss);
    [day2mean, day2std] = get_mice_day_stats(files, [2,2,2], ss);
    [day3mean, day3std] = get_mice_day_stats(files, [3,3,3], ss);
    

    xmean = [day1mean; day2mean; day3mean]';
    xstd = [day1std; day2std; day3std]';

    
    h = make_plot(xmean, xstd);
    
    title(sprintf('Best Fit Orientations (Feature Rich All Contexts)'), 'interpreter', 'none')

    % Save the figure
    outputFolder = projectConfig.analysisFolder; %fullfile(pwd, 'analysis');
    F = getframe(h);
    fnPrefix = 'best_fit_orientations_feature_rich_all_contexts';
    imwrite(F.cdata, fullfile(outputFolder, sprintf('%s.png', fnPrefix)), 'png')
    savefig(h, fullfile(outputFolder, sprintf('%s.fig', fnPrefix)));
    saveas(h, fullfile(outputFolder, sprintf('%s.svg', fnPrefix)), 'svg');
    print('-painters', '-depsc', fullfile(outputFolder,sprintf('%s.eps', fnPrefix)))
    close(h);

end % function

function plot_feature_poor_all_contexts(projectConfig)
    ss = 'best_fit_orientations_all_contexts';
    
    files = {...
        fullfile(projectConfig.analysisFolder, 'feature_poor', 'K1_CA1', 'best_fit_orientations_all_contexts.mat'), ...
        fullfile(projectConfig.analysisFolder, 'feature_poor', 'MG1_CA1', 'best_fit_orientations_all_contexts.mat')};
    
    [day1mean, day1std] = get_mice_day_stats(files, [1,3], ss);
    [day2mean, day2std] = get_mice_day_stats(files, [2,4], ss);
    [day3mean, day3std] = get_mice_day_stats(files, [3,5], ss);
    

    xmean = [day1mean; day2mean; day3mean]';
    xstd = [day1std; day2std; day3std]';

    
    h = make_plot(xmean, xstd);
    
    title(sprintf('Best Fit Orientations (Feature Poor All Contexts)'), 'interpreter', 'none')

    % Save the figure
    outputFolder = projectConfig.analysisFolder; %fullfile(pwd, 'analysis');
    F = getframe(h);
    fnPrefix = 'best_fit_orientations_feature_poor_all_contexts';
    imwrite(F.cdata, fullfile(outputFolder, sprintf('%s.png', fnPrefix)), 'png')
    savefig(h, fullfile(outputFolder, sprintf('%s.fig', fnPrefix)));
    saveas(h, fullfile(outputFolder, sprintf('%s.svg', fnPrefix)), 'svg');
    print('-painters', '-depsc', fullfile(outputFolder,sprintf('%s.eps', fnPrefix)))
    close(h);

end % function

function plot_feature_rich_within_contexts(projectConfig)
    ss = 'best_fit_orientations_within_contexts';
    
    files = {...
        fullfile(projectConfig.analysisFolder, 'feature_rich', 'AK42_CA1', 'best_fit_orientations_within_contexts.mat'), ...
        fullfile(projectConfig.analysisFolder, 'feature_rich', 'AK74_CA1', 'best_fit_orientations_within_contexts.mat'), ...
        fullfile(projectConfig.analysisFolder, 'feature_rich', 'JJ9_CA1', 'best_fit_orientations_within_contexts.mat')};
    
    [day1mean, day1std] = get_mice_day_stats(files, [1,1,1], ss);
    [day2mean, day2std] = get_mice_day_stats(files, [2,2,2], ss);
    [day3mean, day3std] = get_mice_day_stats(files, [3,3,3], ss);
    

    xmean = [day1mean; day2mean; day3mean]';
    xstd = [day1std; day2std; day3std]';

    
    h = make_plot(xmean, xstd);
    
    title(sprintf('Best Fit Orientations (Feature Rich Within Contexts)'), 'interpreter', 'none')

    % Save the figure
    outputFolder = projectConfig.analysisFolder; %fullfile(pwd, 'analysis');
    F = getframe(h);
    fnPrefix = 'best_fit_orientations_feature_rich_within_contexts';
    imwrite(F.cdata, fullfile(outputFolder, sprintf('%s.png', fnPrefix)), 'png')
    savefig(h, fullfile(outputFolder, sprintf('%s.fig', fnPrefix)));
    saveas(h, fullfile(outputFolder, sprintf('%s.svg', fnPrefix)), 'svg');
    print('-painters', '-depsc', fullfile(outputFolder,sprintf('%s.eps', fnPrefix)))
    close(h);

end % function

function plot_feature_poor_within_contexts(projectConfig)
    ss = 'best_fit_orientations_within_contexts';
    
    files = {...
        fullfile(projectConfig.analysisFolder, 'feature_poor', 'K1_CA1', 'best_fit_orientations_within_contexts.mat'), ...
        fullfile(projectConfig.analysisFolder, 'feature_poor', 'MG1_CA1', 'best_fit_orientations_within_contexts.mat')};
    
    [day1mean, day1std] = get_mice_day_stats(files, [1,3], ss);
    [day2mean, day2std] = get_mice_day_stats(files, [2,4], ss);
    [day3mean, day3std] = get_mice_day_stats(files, [3,5], ss);
    

    xmean = [day1mean; day2mean; day3mean]';
    xstd = [day1std; day2std; day3std]';

    
    h = make_plot(xmean, xstd);
    
    title(sprintf('Best Fit Orientations (Feature Poor Within Contexts)'), 'interpreter', 'none')

    % Save the figure
    outputFolder = projectConfig.analysisFolder; %fullfile(pwd, 'analysis');
    F = getframe(h);
    fnPrefix = 'best_fit_orientations_feature_poor_within_contexts';
    imwrite(F.cdata, fullfile(outputFolder, sprintf('%s.png', fnPrefix)), 'png')
    savefig(h, fullfile(outputFolder, sprintf('%s.fig', fnPrefix)));
    saveas(h, fullfile(outputFolder, sprintf('%s.svg', fnPrefix)), 'svg');
    print('-painters', '-depsc', fullfile(outputFolder,sprintf('%s.eps', fnPrefix)))
    close(h);

end % function

function [daymean, daystd] = get_mice_day_stats(filenames, indices, ss)
    numMice = length(filenames);
    values = zeros(numMice, 4);
    for iMouse = 1:numMice
        tmp = load(filenames{iMouse});
        x = tmp.(ss);
        values(iMouse,:) = x(indices(iMouse),:);
    end
    daymean = mean(values,1);
    daystd = std(values,1);
end % function

function [h] = make_plot(xmean, xstd)
    h = figure;
    y1 = xmean;
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
    legend({'day 1', 'day 2', 'day 3'});
    grid on
    grid minor
    set(gca,'XTickLabel',{['0' char(176)], ['90' char(176)], ['180' char(176)], ['270' char(176)]})
    ylabel('Proportion Best Fit', 'fontweight', 'bold')
end % function
