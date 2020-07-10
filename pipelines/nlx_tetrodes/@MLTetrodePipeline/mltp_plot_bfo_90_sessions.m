function mltp_plot_bfo_90_sessions(obj)
    mltp_plot_bfo_general_sessions(obj, 90, 'same');
    mltp_plot_bfo_general_sessions(obj, 90, 'different');
    mltp_plot_bfo_general_sessions(obj, 90, 'all');
    numContexts = obj.Experiment.getNumContexts();
    for iContext = 1:numContexts
        mltp_plot_bfo_general_sessions(obj, 90, sprintf('context%d', iContext));
    end
end % function