function compute_sfp_celllike( obj, session, trial )

%     % Trained on session 1, trial 1 of CMG169_CA1
%     tmp = load('trainedModel.mat', 'trainedModel');
%     trainedModel = tmp.trainedModel;
%     clear tmp

    if isempty(obj.SpatialFootprintTrainedModel)
        warning('Can not compute if spatial footprints are cell-like because no trained model is loaded.');
        return;
    end

    tmp = load(fullfile(trial.getAnalysisDirectory(), sprintf('sfp_compactified.mat')), 'sfp_compactified');
    sfp_compactified = tmp.sfp_compactified;

    yfit = obj.SpatialFootprintTrainedModel.predictFcn(sfp_compactified);
    sfpCellLike = yfit;

    save(fullfile(trial.getAnalysisDirectory(), 'sfp_celllike.mat'), 'sfpCellLike');

end % function
