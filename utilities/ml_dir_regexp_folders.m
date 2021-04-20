function [folders] = ml_dir_regexp_folders(containerFolder, str)
    % Get all of the matching child folders.
    files = dir(fullfile(containerFolder, '*'));
    keep = zeros(1, length(files));
    for i = 1:length(files)
        if regexp(files(i).name, str) & files(i).isdir == 1
            keep(i) = 1;
        else
            keep(i) = 0;
        end
    end
    files(~keep) = [];
    
    folders = cellfun(@(x)(fullfile(containerFolder, x)), {files.name}, 'UniformOutput', false);
end % function