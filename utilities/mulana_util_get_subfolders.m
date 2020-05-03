function [subFolders] = mulana_util_get_subfolders(searchFolder)
    files = dir(fullfile(searchFolder));
    subFolders = {};
    for i = 1:length(files)
        if ~any([strcmp(files(i).name, '.'), strcmp(files(i).name, '..')])
            if files(i).isdir
                subFolders{end+1} = files(i).name;
            end
        end
    end
end
