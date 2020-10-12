function ml_util_bfo_errorbar_groups(angles, groupMean, groupStd)
    numAngles = length(angles);
    
    % Give each group a different color
    numGroups = size(groupMean,1);
    blue = linspace(0.2,1,numGroups);
    %alpha = 0.5.*ones(1, numGroups); %linspace(0.8, 0.2, numGroups);
    alpha = linspace(0.5, 1.0, numGroups); %linspace(0.8, 0.2, numGroups);

    hBar = bar(angles, groupMean');
    for iGroup = 1:numGroups
        %hBar(iGroup).FaceColor = [0, 0, blue(iGroup)];
        %hBar(iGroup).FaceAlpha = alpha(iGroup);
        hBar(iGroup).LineWidth = 2;
    end

    hold on
    for k1 = 1:numGroups
        ctr(k1,:) = bsxfun(@plus, hBar(k1).XData, hBar(k1).XOffset');
        ydt(k1,:) = hBar(k1).YData;
        err1(k1,:) = groupStd(k1,:);
    end
    hold on
    errorbar(ctr, ydt, err1, 'k.', 'linewidth', 2) 
    grid on
    grid minor
    xL = cell(numAngles, 1);
    for iL = 1:numAngles
        xL{iL} = sprintf('%d%c', angles(iL), char(176));
    end
    set(gca, 'xticklabel', xL, 'fontweight', 'bold')
    ylabel('Proportion Best Fit', 'fontweight', 'bold')
end
