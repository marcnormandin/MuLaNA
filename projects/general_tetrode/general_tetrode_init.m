function general_tetrode_init(referenceFolder)

projectType = 'general_tetrode';

fprintf('Select the project instance folder (the project scripts will be saved in it)...\n');
instanceFolder = uigetdir(pwd, 'Select project instance folder to create');
if ~exist(instanceFolder, 'dir')
    fprintf('Creating instance folder (%s) ... ', instanceFolder);
    mkdir(instanceFolder);
    fprintf('done.\n');
end

project.type = projectType;
project.instanceFolder = instanceFolder;
project.projectCreated = datestr(now);

fprintf('Select the parent data directory (that has a subfolder for each animal) ...\n');
project.dataFolder = uigetdir(fullfile(instanceFolder, 'data'), 'Select the parent data directory');

fprintf('Select the parent analysis directory (this will create a subfolder for each animals analysis results)...\n');
project.analysisFolder = uigetdir(fullfile(instanceFolder, 'analysis'), 'Select the parent analysis directory');

if ~exist(project.dataFolder, 'dir')
    fprintf('Creating data folder (%s) ... ', project.dataFolder);
    mkdir(project.dataFolder);
    fprintf('done.\n');
end

if ~exist(project.analysisFolder, 'dir')
    fprintf('Creating analsis folder (%s) ... ', project.analysisFolder);
    mkdir(project.analysisFolder);
    fprintf('done.\n');
end

jsonFilename = fullfile(instanceFolder, 'project_config.json');
jsonTxt = jsonencode(project);
% Make it prettier
jsonTxt = strrep(jsonTxt, ',', sprintf(',\n'));
jsonTxt = strrep(jsonTxt, '[{', sprintf('[\n{\n'));
jsonTxt = strrep(jsonTxt, '}]', sprintf('\n}\n]'));

fid = fopen(jsonFilename, 'w');
if fid == -1
    error('Unable to create the file (%s) for writing.', jsonFilename);
end
fwrite(fid, jsonTxt, 'char');
fclose(fid);
fprintf('Created %s.\n', jsonFilename);
fprintf('Navigate to %s and exeute general_tetrode_run.\n', project.analysisFolder);

% copy all of the files into the instance folder
copyfile(referenceFolder, instanceFolder);

end % function
