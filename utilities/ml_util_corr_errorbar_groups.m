function ml_util_corr_errorbar_groups(groupMean, groupStd)    
    % Give each group a different color
    numGroups = size(groupMean,2);
    blue = linspace(0.5,1,numGroups);
    alpha = linspace(0.8, 0.2, numGroups);
    
    %hBar = bar(1, groupMean);
    hBar = bar(groupMean);
    for iGroup = 1:numGroups
        %hBar(iGroup).FaceColor = [0, 0, blue(iGroup)];
        %hBar(iGroup).FaceAlpha = alpha(iGroup);
%        hBar(iGroup).LineWidth = 2;
    end

    hold on
    for k1 = 1:numGroups
        ctr(k1,:) = bsxfun(@plus, hBar(k1).XData, hBar(k1).XOffset');
        ydt(k1,:) = hBar(k1).YData;
        err1(k1,:) = groupStd(k1,:);
    end
    hold on
    %errorbar(ctr, ydt, err1, 'k.', 'linewidth', 2) 
    grid on
    grid minor

    ylabel('Correlation', 'fontweight', 'bold')
end