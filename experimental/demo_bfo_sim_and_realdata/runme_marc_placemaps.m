close all
clear all
clc

sessionMapParentFolder = 'M:\Minimice\CMG162_CA1\celia_analysis_20210225\CMG162_sq_ratemaps\s1';
trialFolders = ml_nlx_dir_trial_folders(sessionMapParentFolder);

numTrials = length(trialFolders);

% Get the maximum map number used
maxId = 0;
for iTrial = 1:numTrials
    tf = trialFolders{iTrial};
    placemapFilenames = ml_nlx_dir_placemaps(tf);
    numMaps = length(placemapFilenames);
    for iMap = 1:numMaps
        [filepath, name, ext] = fileparts(placemapFilenames{iMap});
        % strip the 'pm_' to get the number
        gid = str2double(name(4:end));
        if gid > maxId
            maxId = gid;
        end
    end
end

% Now read in all of the placemaps into memory to do the math faster.
placemaps = cell(maxId, numTrials);
for iTrial = 1:numTrials
    tf = trialFolders{iTrial};
    placemapFilenames = ml_nlx_dir_placemaps(tf);
    numMaps = length(placemapFilenames);
    for iMap = 1:numMaps
        [filepath, name, ext] = fileparts(placemapFilenames{iMap});
        % strip the 'pm_' to get the number
        gid = str2double(name(4:end));
        x = load(placemapFilenames{iMap});
        pm = x.tc;
        placemaps{gid, iTrial} = pm;
    end
end

% Now do the bfo
perCell = struct('v_all', [], 'vind_all', []);                
total_vind_all = [];
for gid = 1:maxId
    perCell(gid).v_all = [];
    perCell(gid).vind_all = [];
    
   for iTrial1 = 1:numTrials
       pm1 = placemaps{gid, iTrial1};
      
       if isempty(pm1)
           continue; % skip
       end
       
       W1 = ones(size(pm1));
       W1(pm1 == 0) = nan;
       
       for iTrial2 = 1:numTrials
           pm2 = placemaps{gid, iTrial2};
           if isempty(pm2)
               continue; % skip
           end
           W2 = ones(size(pm2));
           W2(pm2 == 0) = nan;
           
           [vn, vindn] = ml_core_max_pixel_rotated_pixel_cross_correlation_90deg(pm1, pm2, 'W1',W1,'W2',W2);
           
           if length(vindn) ~= 1
               error('%d %d', gid, iTrial2)
           end
           
           perCell(gid).v_all(end+1) = vn;
           perCell(gid).vind_all(end+1) = vindn;
       end
   end
   
   hc = histcounts(perCell(gid).vind_all, 1:5);
   mv = max(hc);
   mi = find(hc == mv);
   total_vind_all = [total_vind_all, mi];
end

total_hc = histcounts(total_vind_all, 1:5);
figure
bar(total_hc)


function [trialFolders] = ml_nlx_dir_trial_folders(containerFolder)
    % Get all of the regular cluster files. Do not keep autosave.clusters or
    % anything else that is not like TT#.clusters.
    files = dir(fullfile(containerFolder, '*'));
    keep = zeros(1, length(files));
    for i = 1:length(files)
        if regexp(files(i).name, '^(trial_)\d+$') & files(i).isdir == 1
            keep(i) = 1;
        else
            keep(i) = 0;
        end
    end
    files(~keep) = [];
    
    trialFolders = cellfun(@(x)(fullfile(containerFolder, x)), {files.name}, 'UniformOutput', false);
end % function

function [placemapFilenames] = ml_nlx_dir_placemaps(trialFolder)
    % Get all of the regular cluster files. Do not keep autosave.clusters or
    % anything else that is not like TT#.clusters.
    files = dir(fullfile(trialFolder, 'pm_*.mat'));
    keep = zeros(1, length(files));
    for i = 1:length(files)
        if regexp(files(i).name, '^(pm_)\d+(.mat)$') & files(i).isdir == 0
            keep(i) = 1;
        else
            keep(i) = 0;
        end
    end
    files(~keep) = [];
    
    placemapFilenames = cellfun(@(x)(fullfile(trialFolder, x)), {files.name}, 'UniformOutput', false);
end % function
