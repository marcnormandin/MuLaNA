function [results] = ml_dir_regexp_files(containerFolder, str, searchAllSubFolders)
    if searchAllSubFolders == 1
        files = dir(fullfile(containerFolder, '**'));
    else
        files = dir(fullfile(containerFolder, '*'));
    end
    keep = zeros(1, length(files));
    for i = 1:length(files)
        if regexp(files(i).name, str) & files(i).isdir == 0
            keep(i) = 1;
        else
            keep(i) = 0;
        end
    end
    files(~keep) = [];
    
    results = cellfun(@(x,y)(fullfile(x,y)), {files.folder}, {files.name}, 'UniformOutput', false);
end % function