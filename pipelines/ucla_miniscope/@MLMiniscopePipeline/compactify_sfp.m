function compactify_sfp( obj, session, trial )
    % Load the standard SFP used for CellReg
    fn = fullfile(trial.getAnalysisDirectory(), sprintf('%s.mat', obj.Config.cell_registration.spatialFootprintFilenamePrefix));
    if ~isfile(fn)
        fn = fullfile(trial.getAnalysisDirectory(), 'sfp.mat');
        if ~isfile(fn)
            error('Unable to load spatial footprints.');
        end
    end
    tmp = load(fn);
    SFP = tmp.SFP;

    % Compactified SFP will have the following data for each cell
    data = struct('id', [], 'full_width', [], 'full_height', [], 'compact_width', [], 'compact_height', [], 'offset_width', [], 'offset_height', [], 'compact_sfp', []);

    for iCell = 1:size(SFP,1)
        F = squeeze(SFP(iCell,:,:));

        full_height = size(F,1);
        full_width = size(F,2);

        [compact_sfp,offset_height,offset_width] = ml_core_remove_zero_padding(F);
        compact_height = size(compact_sfp,1);
        compact_width = size(compact_sfp,2);

        [stats] = ml_cai_spatialfootprint_stats(compact_sfp);
        f = fields(stats);
        for iField = 1:length(f)
            data(iCell).(f{iField}) = stats.(f{iField});
        end
        data(iCell).use = true;

        % Reconstructed
        R = zeros(full_height, full_width);
        R(offset_height+1:(offset_height+compact_height), offset_width+1:(offset_width+compact_width)) = compact_sfp;
        %R

        % Store
        data(iCell).id = iCell;
        data(iCell).full_width = full_width;
        data(iCell).full_height = full_height;
        data(iCell).compact_width = compact_width;
        data(iCell).compact_height = compact_height;
        data(iCell).offset_width = offset_width;
        data(iCell).offset_height = offset_height;
        data(iCell).compact_sfp = compact_sfp;
    end

    % Convert to table (for machine learning) and store
    sfp_compactified = struct2table(data);
    save(fullfile(trial.getAnalysisDirectory(), sprintf('sfp_compactified.mat')), 'sfp_compactified');
end % function
