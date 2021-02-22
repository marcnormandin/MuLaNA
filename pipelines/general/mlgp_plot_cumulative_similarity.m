function [h] = mlgp_plot_cumulative_similarity(obj, session)

    tmp = load( fullfile(session.getAnalysisDirectory(), 'best_fit_orientations', 'bfo_180_percell.mat') );
    perCell = tmp.perCell;

    t = {'all', 'same' , 'different', 'context1', 'context2'};
    h = figure;

    for it = 1:length(t)
        X = [perCell.(sprintf('v_%s', t{it}))];
        X(isnan(X)) = [];

        x = sort(unique(X));
        p = zeros(1, length(x));
        for i = 1:length(x)
           p(i) = sum(X <= x(i)); 
        end
        p = p ./ length(X);

        plot(x,p, 'linewidth', 2)
        hold on

        xlim([-1, 1])

    end % i
    legend(t, 'location', 'southoutside', 'orientation', 'horizontal')

    grid on
    xlabel('Correlation')
    ylabel('Cumulative Similarity')
    set(gca, 'fontweight', 'bold')
    set(gca, 'fontsize', 12)
    title(sprintf('%s: %s', obj.Experiment.getAnimalName(), session.getName()), 'interpreter', 'none')
end % function
