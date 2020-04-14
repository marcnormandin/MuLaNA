function [projectsAvailable, projectsFolder] = mulana_project_helper_get_list()

testFile = 'mulana_project_list.m';
testFileFound = which(testFile);
if isempty(testFileFound)
    error('Something must be wrong with your MuLaNA installation because the file %s could not be found.', testFile);
end

dt = dir(testFileFound);
projectsFolder = dt.folder;
d = dir(fullfile(projectsFolder, '*'));

projectsAvailable = {};
for iD = 1:length(d)
    f = d(iD);
    if f.isdir && strcmp(f.name, '.') == 0 && strcmp(f.name, '..') == 0
        projectsAvailable{end+1} = f.name;
    end
end % iD

end % function
