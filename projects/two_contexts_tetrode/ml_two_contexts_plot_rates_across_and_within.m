function ml_two_contexts_plot_rates_across_and_within(projectConfig)
    statField1 = 'meanFiringRate';
    plot_feature_rich(projectConfig, statField1);
    plot_feature_poor(projectConfig, statField1);
    
    statField2 = 'peakFiringRate';
    plot_feature_rich(projectConfig, statField2);
    plot_feature_poor(projectConfig, statField2);
    
    statField3 = 'informationRate';
    plot_feature_rich(projectConfig, statField3);
    plot_feature_poor(projectConfig, statField3);
end % function

function plot_feature_rich(projectConfig, statField)
    
    files = {...
        fullfile(projectConfig.analysisFolder, 'feature_rich', 'AK42_CA1'), ...
        fullfile(projectConfig.analysisFolder, 'feature_rich', 'AK74_CA1'), ...
        fullfile(projectConfig.analysisFolder, 'feature_rich', 'JJ9_CA1')};
    
    [day1mean, day1std] = get_mice_day_stats(files, {'d7', 'd1', 'd1'}, statField);
    [day2mean, day2std] = get_mice_day_stats(files, {'d8', 'd2', 'd2'}, statField);
    [day3mean, day3std] = get_mice_day_stats(files, {'d9', 'd3', 'd3'}, statField);
    

    xmean = [day1mean; day2mean; day3mean]';
    xstd = [day1std; day2std; day3std]';

    
    h = make_plot(xmean, xstd);
    
    title(sprintf('%s (Feature Rich)', statField), 'interpreter', 'none')

    % Save the figure
    outputFolder = projectConfig.analysisFolder; %fullfile(pwd, 'analysis');
    F = getframe(h);
    fnPrefix = sprintf('plot_%s_feature_rich', statField);
    imwrite(F.cdata, fullfile(outputFolder, sprintf('%s.png', fnPrefix)), 'png')
    savefig(h, fullfile(outputFolder, sprintf('%s.fig', fnPrefix)));
    saveas(h, fullfile(outputFolder, sprintf('%s.svg', fnPrefix)), 'svg');
    print('-painters', '-depsc', fullfile(outputFolder,sprintf('%s.eps', fnPrefix)))
    close(h);

end % function

function plot_feature_poor(projectConfig, statField)
    
    files = {...
        fullfile(projectConfig.analysisFolder, 'feature_poor', 'K1_CA1'), ...
        fullfile(projectConfig.analysisFolder, 'feature_poor', 'MG1_CA1')};
    
    [day1mean, day1std] = get_mice_day_stats(files, {'d1', 's9'}, statField);
    [day2mean, day2std] = get_mice_day_stats(files, {'d2', 's10'}, statField);
    [day3mean, day3std] = get_mice_day_stats(files, {'d3', 's11'}, statField);
    

    xmean = [day1mean; day2mean; day3mean]';
    xstd = [day1std; day2std; day3std]';

    
    h = make_plot(xmean, xstd);
    
    title(sprintf('%s (Feature Poor)', statField), 'interpreter', 'none')

    % Save the figure
    outputFolder = projectConfig.analysisFolder; %fullfile(pwd, 'analysis');
    F = getframe(h);
    fnPrefix = sprintf('plot_%s_feature_poor', statField);
    imwrite(F.cdata, fullfile(outputFolder, sprintf('%s.png', fnPrefix)), 'png')
    savefig(h, fullfile(outputFolder, sprintf('%s.fig', fnPrefix)));
    saveas(h, fullfile(outputFolder, sprintf('%s.svg', fnPrefix)), 'svg');
    print('-painters', '-depsc', fullfile(outputFolder,sprintf('%s.eps', fnPrefix)))
    close(h);

end % function



function [daymean, daystd] = get_mice_day_stats(filenames, subfolders, statField)
    numMice = length(filenames);
    similarity = [];
    for iMouse = 1:numMice
        tmp = load( fullfile(filenames{iMouse}, subfolders{iMouse}, 'pfStats.mat') );
        pfStats = tmp.pfStats;
        
        
        numCells = tmp.numTFiles; %size(pfStats,1);
        numTrials = tmp.numTrials; %size(pfStats,2);
        
        context_id = zeros(numCells, numTrials); %tmp.pfStats.context_id
        context_use = zeros(numCells, numTrials); %tmp.pfStats.context_use;\
        stat = zeros(numCells, numTrials);
        for iCell = 1:numCells
            for iTrial = 1:numTrials
                context_id(iCell, iTrial) = pfStats(iCell).context_id(iTrial);
                context_use(iCell, iTrial) = pfStats(iCell).context_use(iTrial);
                stat(iCell, iTrial) = pfStats(iCell).(statField)(iTrial);
            end
        end
        
        for iCell = 1:numCells
            s = stat(iCell,:);
            c = context_id(iCell,:);
            u = context_use(iCell,:);
            rate = {};
            % This assumes only two contexts (which is what we have)
            for iContext = 1:2
                indices = intersect( find(c == iContext), find(u == true) );
                rate{iContext} = s(indices);
            end
            
            % Average difference within contexts
            rate_within = 0;
            rate_within_count = 0;
            
            for iContext = 1:2
                r = rate{iContext};
                for iR = 1:length(r)-1
                    for jR = iR+1:length(r)
                        rate_within = rate_within + abs(r(iR) - r(jR));
                        rate_within_count = rate_within_count + 1;
                    end
                end
            end
            rate_within = rate_within / rate_within_count;
            
            % Average difference across contexts
            rate_across = 0;
            rate_across_count = 0;
            
            r1 = rate{1};
            r2 = rate{2};

            for iR = 1:length(r1)
                for jR = 1:length(r2)
                    rate_across = rate_across + abs(r1(iR) - r2(jR));
                    rate_across_count = rate_across_count + 1;
                end
            end
            rate_across = rate_across / rate_across_count;
                
            similarity(end+1) = abs(rate_across - rate_within) / rate_across;
        end % iCell
    end % iMouse
    
    daymean = mean(similarity);
    daystd = std(similarity);
end % function

function [h] = make_plot(xmean, xstd)
    h = figure;
    y1 = xmean;
    hBar = bar(y1);
    hBar(1).FaceColor = [0, 0, 0.5];
    hBar(1).FaceAlpha = 0.6;
    hBar(1).LineWidth = 2;

    legend({'day 1', 'day 2', 'day 3'});
    grid on
    grid minor
    %set(gca,'XTickLabel',{['0' char(176)], ['90' char(176)], ['180' char(176)], ['270' char(176)]})
    ylabel('(rate_{across} - rate_{within})/rate_{across}', 'fontweight', 'bold')
end % function
