function two_contexts_tetrode_init(referenceFolder)

projectType = 'two_contexts_tetrode';

fprintf('Select the project instance folder (the project scripts will be saved in it)...\n');
instanceFolder = uigetdir(pwd, 'Select project instance folder');
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

project.dataFeaturePoorFolder = fullfile(project.dataFolder, 'feature_poor');
project.dataFeatureRichFolder = fullfile(project.dataFolder, 'feature_rich');
project.analysisFeaturePoorFolder = fullfile(project.analysisFolder, 'feature_poor');
project.analysisFeatureRichFolder = fullfile(project.analysisFolder, 'feature_rich');


if ~exist(project.dataFolder, 'dir')
    fprintf('Creating data folder (%s) ... ', project.dataFolder);
    mkdir(project.dataFolder);
    fprintf('done.\n');
end

if ~exist(project.dataFeaturePoorFolder, 'dir')
    fprintf('Creating data folder (%s) ... ', project.dataFeaturePoorFolder);
    mkdir(project.dataFeaturePoorFolder);
    fprintf('done.\n');
end

if ~exist(project.dataFeatureRichFolder, 'dir')
    fprintf('Creating data folder (%s) ... ', project.dataFeatureRichFolder);
    mkdir(project.dataFeatureRichFolder);
    fprintf('done.\n');
end

if ~exist(project.analysisFolder, 'dir')
    fprintf('Creating analsis folder (%s) ... ', project.analysisFolder);
    mkdir(project.analysisFolder);
    fprintf('done.\n');
end

if ~exist(project.analysisFeaturePoorFolder, 'dir')
    fprintf('Creating analsis folder (%s) ... ', project.analysisFeaturePoorFolder);
    mkdir(project.analysisFeaturePoorFolder);
    fprintf('done.\n');
end

if ~exist(project.analysisFeatureRichFolder, 'dir')
    fprintf('Creating analsis folder (%s) ... ', project.analysisFeatureRichFolder);
    mkdir(project.analysisFeatureRichFolder);
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

% copy all of the files into the instance folder
copyfile(referenceFolder, instanceFolder);

end % function
