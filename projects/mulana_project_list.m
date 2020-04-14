function mulana_project_list()
% This code lists all of the available projects for a user

[projectsAvailable, ~] = mulana_project_helper_get_list();

if isempty(projectsAvailable)
    fprintf('Apparently there are no projects, but there were when I made this!\n');
else
    fprintf('The following projects are available:\n');
    for i = 1:length(projectsAvailable)
        fprintf('\t%s\n', projectsAvailable{i});
    end
end

end % function
