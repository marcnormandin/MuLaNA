function mltp_plot_bfo_general_sessions(obj, rotDeg, group)
    numAngles = 360/rotDeg;
    angles = (0:numAngles-1)*rotDeg;
    
    % Load the data
    fn = fullfile(obj.Experiment.getAnalysisParentDirectory(), sprintf('bfo_%d_%s_avg.mat', rotDeg, group));
    if ~isfile(fn)
        error("The file (%s) does not exist. Can't make the plot", fn);
    end
    
    tmp = load(fn);
    bfo_session_prob = tmp.bfo_session_prob;
    bfo_session_corr = tmp.bfo_session_corr;
    
    
    % All of the sessions
    h = figure('Name', sprintf('Best Fit Orientations (%s contexts) ( %s )', group, obj.Experiment.getAnimalName()), 'Position', get(0,'Screensize'));
    subplot(2,1,1)
    bar(angles, bfo_session_prob');
    hold on 
    grid on
    title(sprintf('Best Fit Orientations (all contexts) ( %s )', obj.Experiment.getAnimalName()), 'Interpreter', 'none')
    ylabel('Proportion Best Fit')
    
    xL = cell(numAngles, 1);
    for iL = 1:numAngles
        xL{iL} = sprintf('%d%c', angles(iL), char(176));
    end
    xticklabels( xL );
    legend(tmp.bfo_session_name)
    
    subplot(2,1,2)
    plot(1:length(bfo_session_corr), bfo_session_corr, 'r*-')
    xticklabels(tmp.bfo_session_name);
    xlabel('Session')
    grid on
    title('Average Correlation')
    
    
    outputFolder = obj.Experiment.getAnalysisParentDirectory();
    F = getframe(h);
    
    prefix = sprintf('bfo_%d_%s', rotDeg, group);
    imwrite(F.cdata, fullfile(outputFolder, sprintf('%s.png', prefix)), 'png')
    savefig(h, fullfile(outputFolder, sprintf('%s.fig', prefix)));
    saveas(h, fullfile(outputFolder, sprintf('%s.svg', prefix)), 'svg');
    print('-painters', '-depsc', fullfile(outputFolder, sprintf('%s.eps', prefix)))
    close(h);
end % function