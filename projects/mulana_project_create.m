function mulana_project_create(projectType)

[projectsAvailable, projectFolder] = mulana_project_helper_get_list();

if nargin ~= 1
    error('A project type must be specified as one of the following: %s', [strjoin(projectsAvailable, ', ') '.']);
end

if ismember(projectType, projectsAvailable)
    referenceFolder = fullfile(projectFolder, projectType);
        
    % Execute the projects initialization script
    eval( sprintf("%s_init('%s')", projectType, referenceFolder) );
    
    fprintf('Project created!\n');
else
    disp(projectsAvailable)
    error('The project (%s) is not available.\n', projectName);
end

end % function
