

function [daymean, daystd] = get_mice_day_stats(filenames, indices)
    numMice = length(filenames);
    values = zeros(numMice, 4);
    for iMouse = 1:numMice
        tmp = load(filenames{iMouse});
        x = tmp.best_fit_orientations_all_contexts;
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
