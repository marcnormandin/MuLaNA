function mlgp_plot_bfo_90_sessions(obj)
    mlgp_plot_bfo_general_sessions(obj, 90, 'same');
    mlgp_plot_bfo_general_sessions(obj, 90, 'different');
    mlgp_plot_bfo_general_sessions(obj, 90, 'all');
    numContexts = obj.Experiment.getNumContexts();
    for iContext = 1:numContexts
        mlgp_plot_bfo_general_sessions(obj, 90, sprintf('context%d', iContext));
    end
end % function