function mltp_plot_bfo_180_sessions(obj)
    mltp_plot_bfo_general_sessions(obj, 180, 'same');
    mltp_plot_bfo_general_sessions(obj, 180, 'different');
    mltp_plot_bfo_general_sessions(obj, 180, 'all');
    numContexts = obj.Experiment.getNumContexts();
    for iContext = 1:numContexts
        mltp_plot_bfo_general_sessions(obj, 180, sprintf('context%d', iContext));
    end
end % function