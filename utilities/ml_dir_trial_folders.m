function [trialFolders] = ml_dir_trial_folders(containerFolder)
    % Get all of the trial folders.
    files = dir(fullfile(containerFolder, '*'));
    keep = zeros(1, length(files));
    for i = 1:length(files)
        if regexp(files(i).name, '^(trial_)\d+$') & files(i).isdir == 1
            keep(i) = 1;
        else
            keep(i) = 0;
        end
    end
    files(~keep) = [];
    
    trialFolders = cellfun(@(x)(fullfile(containerFolder, x)), {files.name}, 'UniformOutput', false);
end % function