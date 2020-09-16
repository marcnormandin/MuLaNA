function mlgp_plot_bfo_general_sessions(obj, rotDeg, group)
    numAngles = 360/rotDeg;
    angles = (0:numAngles-1)*rotDeg;
    
    % Load the data
    fn = fullfile(obj.Experiment.getAnalysisParentDirectory(), sprintf('bfo_%d_%s_avg.mat', rotDeg, group));
    if ~isfile(fn)
        error("The file (%s) does not exist. Can't make the plot", fn);
    end
    
    tmp = load(fn);
    bfo_session_prob_mean = tmp.bfo_session_prob_mean;
    bfo_session_prob_std = tmp.bfo_session_prob_std;
    bfo_session_corr_mean = tmp.bfo_session_corr_mean;
    bfo_session_corr_std = tmp.bfo_session_corr_std;
    
    %bfo_session_corr = tmp.bfo_session_corr;
    
    
    % All of the sessions
    h = figure('Name', sprintf('Best Fit Orientations (%s contexts) ( %s )', group, obj.Experiment.getAnimalName()), 'Position', get(0,'Screensize'));
    %subplot(2,1,1)
    %bar(angles, bfo_session_prob');
    ml_util_bfo_errorbar_groups(angles, bfo_session_prob_mean, bfo_session_prob_std)
    
    hold on 
    grid on
    title(sprintf('Best Fit Orientations\n%s (%s contexts)', obj.Experiment.getAnimalName(), group), 'Interpreter', 'none')
%     ylabel('Proportion Best Fit', 'fontweight', 'bold')
    
%     xL = cell(numAngles, 1);
%     for iL = 1:numAngles
%         xL{iL} = sprintf('%d%c', angles(iL), char(176));
%     end
%     xticklabels( xL );
    legend(tmp.bfo_session_name)
    
    %subplot(2,1,2)
    %plot(1:length(bfo_session_corr), bfo_session_corr, 'r*-')
    %ml_util_corr_errorbar_groups(bfo_session_corr_mean, bfo_session_corr_std)
    %legend(tmp.bfo_session_name)

    %xticklabels(tmp.bfo_session_name);
    %xlabel('Session')
    grid on
    %title('Average Correlation')
    
    
    outputFolder = obj.Experiment.getAnalysisParentDirectory();
    F = getframe(h);
    
    prefix = sprintf('bfo_%d_%s', rotDeg, group);
    imwrite(F.cdata, fullfile(outputFolder, sprintf('%s.png', prefix)), 'png')
    savefig(h, fullfile(outputFolder, sprintf('%s.fig', prefix)));
    saveas(h, fullfile(outputFolder, sprintf('%s.svg', prefix)), 'svg');
    print('-painters', '-depsc', fullfile(outputFolder, sprintf('%s.eps', prefix)))
    close(h);
end % function