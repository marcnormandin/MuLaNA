function [trialFolders] = ml_cai_io_trialfolders_find(experimentFolder)

% Check if the experiment folder exists (it may not due to user error)
if ~isfolder( experimentFolder )
    error("The folder (%s) does not exist so we can not find any trial folders inside of it.", experimentFolder);
end

d = dir( sprintf('%s/H*', experimentFolder) );
trialFolders = d([d(:).isdir]==1);
trialFolders = trialFolders(~ismember({trialFolders(:).name},{'.','..','cellreg','DARK_FRAMES', 'DARKFRAMES', 'UNUSED'}));
for iTrialFolder = 1:length(trialFolders)
    
    s = split(trialFolders(iTrialFolder).name, '_');
    if length(s) ~= 3
        fprintf('%s\n',trialFolders(iTrialFolder).name);
        error('Invalid trial time coding. Must be H#_M#_S#.');
    end
    
    h = str2double(s{1}(2:end));
    m = str2double(s{2}(2:end));
    s = str2double(s{3}(2:end));
    v = h*3600 + m*60 + s;
    
    trialFolders(iTrialFolder).seconds = v;
end

% Sort by increasing time
trialFolders = table2struct(sortrows(struct2table(trialFolders),7));

end % function
