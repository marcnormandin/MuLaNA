function mulana_project_create(projectName)
outputFolder = fullfile(pwd, projectName);

%projectName = 'object_task_consecutive_trials';
[projectsAvailable, projectFolder] = mulana_project_helper_get_list();

if ismember(projectName, projectsAvailable)
    inputFolder = fullfile(projectFolder, projectName);
    
    copyfile(inputFolder, outputFolder);
    
    fprintf('Project created!\n');
else
    disp(projectsAvailable)
    error('The project (%s) is not available.\n', projectName);
end

end % function
