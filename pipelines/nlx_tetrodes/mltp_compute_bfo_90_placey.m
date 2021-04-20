function mltp_compute_bfo_90_placey(obj, session)
    outputFolder = fullfile(session.getAnalysisDirectory(), obj.Config.best_fit_orientations_placey.outputFolder);

    rotDeg = 90;
    numContexts = obj.Experiment.getNumContexts();
    
    mirrorContexts = zeros(1,numContexts); % Set entry to 1 to mirror the context
    
    [perCell, total] = mltp_compute_bfo_general_placey(obj, session, rotDeg, mirrorContexts);

    helper_bfo_save_data_placey(outputFolder, perCell, rotDeg, 'same');
    helper_bfo_save_data_placey(outputFolder, perCell, rotDeg, 'different');
    helper_bfo_save_data_placey(outputFolder, perCell, rotDeg, 'all');
    for iContext = 1:numContexts
        helper_bfo_save_data_placey(outputFolder, perCell, rotDeg, sprintf('context%d', iContext));
    end
    helper_bfo_save_percell_placey(outputFolder, perCell, rotDeg);
    helper_bfo_save_total_placey(outputFolder, total, rotDeg);
    
end % function
