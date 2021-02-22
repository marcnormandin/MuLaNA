function [T] = ml_util_pfstats_struct_to_table(pfStats)
    % This code converts the pfStats structure into a table. It has to
    % first be loaded to memory.

    numCells = length(pfStats);

    % All of the fields
    fieldNames = fields(pfStats);

    % The t filenames are not in an array of 1xtrials like the others so we
    % have to treat it uniquely.
    perTrialFieldNames = fieldNames(~ismember(fieldNames, 'tFilePrefix'));

    numFields = length(perTrialFieldNames);

    s = [];
    row = 1;
    for iCell = 1:numCells
        numTrials = length(pfStats(1).meanFiringRate); % Use this as example to get the number of trials as each field will have the same number.
        for iTrial = 1:numTrials
            s(row).('tFilePrefix') = pfStats(iCell).('tFilePrefix');
            for iField = 1:numFields
                f = perTrialFieldNames{iField};
                s(row).(f) = pfStats(iCell).(f)(iTrial);

            end

            % Add in the trial number
            s(row).('trial_index') = iTrial;

            % Add in the cell index
            s(row).('cell_index') = iCell;

            % On to the next row
            row = row + 1;
        end
    end
    T = struct2table(s);
end