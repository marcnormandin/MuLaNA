function mltp_compute_bfo_180(obj, session)
    % We don't need the shrunk data.
    outputFolder = fullfile(session.getAnalysisDirectory(), obj.Config.best_fit_orientations.outputFolder);

    rotDeg = 180;
    numContexts = obj.Experiment.getNumContexts();
    mirrorContexts = zeros(1, numContexts); % Set entry to 1 to mirror the associated context
    
    [perCell, total] = mltp_compute_bfo_general(obj, session, rotDeg, mirrorContexts);

    helper_bfo_save_data(outputFolder, perCell, rotDeg, 'same');
    helper_bfo_save_data(outputFolder, perCell, rotDeg, 'different');
    helper_bfo_save_data(outputFolder, perCell, rotDeg, 'all');
    for iContext = 1:numContexts
        helper_bfo_save_data(outputFolder, perCell, rotDeg, sprintf('context%d', iContext));
    end
    helper_bfo_save_percell(outputFolder, perCell, rotDeg);
    helper_bfo_save_total(outputFolder, total, rotDeg);
end % function

