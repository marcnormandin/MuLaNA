function mltp_compute_bfo_general_average(obj, rotDeg, group)

    numAngles = 360 / rotDeg;
    
    bfo_session_prob = zeros(obj.Experiment.getNumSessions(), numAngles);
    bfo_session_corr = zeros(obj.Experiment.getNumSessions(), 1);
    bfo_session_name = cell(obj.Experiment.getNumSessions(), 1);
    
    % Load and store each sessions bfo data
    for iSession = 1:obj.Experiment.getNumSessions()
        session = obj.Experiment.getSession(iSession);
        
        dataFolder = fullfile(session.getAnalysisDirectory(), obj.Config.best_fit_orientations.outputFolder);
        tmp = load(fullfile(dataFolder,sprintf('bfo_%d_%s.mat', rotDeg, group )));
        
        bfo_session_prob(iSession,:) = tmp.avg_prob;
        bfo_session_corr(iSession,1) = tmp.avg_corr;
        bfo_session_name{iSession} = session.getName();
    end
    
    % Compute the averages
    bfo_prob_avg = mean(bfo_session_prob, 1);
    bfo_prob_std = std(bfo_session_prob, 1);
    
    bfo_corr_avg = mean(bfo_session_corr, 1);
    bfo_corr_std = std(bfo_session_corr, 1);

    outputFolder = obj.Experiment.getAnalysisParentDirectory();
    save(fullfile(outputFolder, sprintf('bfo_%d_%s_avg.mat', rotDeg, group)), ...
        'bfo_session_name', ...
        'bfo_session_prob', 'bfo_session_corr', ...
        'bfo_prob_avg', 'bfo_prob_std', ...
        'bfo_corr_avg', 'bfo_corr_std');

end % function