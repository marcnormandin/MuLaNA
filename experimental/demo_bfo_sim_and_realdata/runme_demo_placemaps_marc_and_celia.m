% 2020-02-25. Marc wrote this code to compare the same BFO90 computation on
% the placemaps of Celia or my own. For a DIRECT comparison. Nothing is
% used but the maps.

% 2020-02-26. Added simulated data to test the core algorithm before it is
% applied to real data. Added min correlation value and min number of
% comparisons. Added inclusion of angle if within threshold (0.2) of the
% maximum correlation value.

%close all
clear all
clc

% Uncomment one of these
whose_data = 'marc';
%whose_data = 'celia';
%whose_data = 'simulated';

% Pick a session
sessionName = 's3';

% Change the outer directories of the folder containing s1, s2, s3, etc
% analysis folders to what you have on your system. Below is what I have on
% mine.
if strcmpi(whose_data, 'marc')
    %sessionMapParentFolder = fullfile('M:\Minimice\CMG162_CA1\analysis\chengs_task_2c', sessionName);
    sessionMapParentFolder = fullfile('M:\Minimice\CMG169_CA1\analysis\chengs_task_2c', sessionName);
elseif strcmpi(whose_data, 'celia') || strcmpi(whose_data, 'simulated')
    sessionMapParentFolder = fullfile('M:\Minimice\CMG162_CA1\celia_analysis_20210225\CMG162_sq_ratemaps', sessionName);        
else
    error('only marc and celia work work work!')
end

trialFolders = ml_nlx_dir_trial_folders(sessionMapParentFolder);

numTrials = length(trialFolders);


% Get the maximum map number used
maxId = 0;
for iTrial = 1:numTrials
    tf = trialFolders{iTrial};
    
    placemapFilenames = ml_nlx_dir_placemaps(tf, whose_data);

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

%%
cell_use = [];
if strcmpi(whose_data, 'marc')
    cell_use = nan(maxId, numTrials);
end

%%

% Now read in all of the placemaps into memory to do the math faster.
fprintf('Loading placemaps (%s)... ', whose_data);
placemaps = cell(maxId, numTrials);
extra = nan(maxId, numTrials);



for iTrial = 1:numTrials
    tf = trialFolders{iTrial};
    placemapFilenames = ml_nlx_dir_placemaps(tf, whose_data);
    numMaps = length(placemapFilenames);
    
    if strcmpi(whose_data, 'marc')
        x = load(fullfile(tf, 'cell_use.mat'));
        cell_use(:,iTrial) = x.cell_use;
    end
    
    % Load whether or not to use the cells
    for iMap = 1:numMaps
        [filepath, name, ext] = fileparts(placemapFilenames{iMap});
        % strip the 'pm_' to get the number
        gid = str2double(name(4:end));
        
        [pm,e] = ml_load_placemap_data(placemapFilenames{iMap}, whose_data);
        placemaps{gid, iTrial} = pm;
        
        %if strcmpi(whose_data, 'marc') ~= 1
        extra(gid, iTrial) = e;
    end
end
fprintf('done!\n');


%% NOW DO THE BF0 90 (ALL)

perCell = struct('v_all', [], 'vind_all', []);
                
total_vind_all = [];
for gid = 1:maxId
    perCell(gid).v_all = [];
    perCell(gid).vind_all = [];
    
   for iTrial1 = 1:numTrials
       pm1 = placemaps{gid, iTrial1};
      
       if isempty(pm1) || ~any(pm1, 'all')
           continue; % skip
       end
       
       if ~isempty(cell_use)
           u1 = cell_use(gid, iTrial1);
           if u1 == 0
               continue;
           end
       end
       
       W1 = ones(size(pm1));
       W1(pm1 == 0) = nan;
       
       for iTrial2 = 1:numTrials
           
           if iTrial1 == iTrial2
               continue; % skip
           end
           
           if ~isempty(cell_use)
               u2 = cell_use(gid, iTrial2);
               if u2 == 0
                   continue;
               end
           end
           
           pm2 = placemaps{gid, iTrial2};
           if isempty(pm2) || ~any(pm2, 'all')
               continue; % skip
           end
           W2 = ones(size(pm2));
           W2(pm2 == 0) = nan;
           
           %[vn, vindn] = ml_core_max_pixel_rotated_pixel_cross_correlation_90deg(pm1, pm2, 'W1',W1,'W2',W2);
           

           
           
            numRotations = 4;
            r = zeros(1,numRotations);
            for k = 1:numRotations
                % Rotate T2 counter-clockwise
                pm2Rot = rot90(pm2, k-1);
                W2Rot = rot90(W2, k-1);
                
                a1 = find(W1 == 1);
                a2 = find(W2Rot == 1);
                a = intersect(a1, a2);
                x1 = pm1(a);
                x2 = pm2Rot(a);
                
                r(k) = corr(x1, x2);
                %r(k) = ml_core_pixel_pixel_cross_correlation_compute(pm1, pm2Rot, 'W1',W1, 'W2', W2Rot);
            end
            mv = max(r);
            mi = intersect(find(r >= mv - 0.1), find(r <= mv + 0.1));
            vn = mv;
            vindn = mi;
%             r;
%             vn = max(r);
%             vindn = find(r == vn);
%            if length(vindn) ~= 1
%                error('%d %d', gid, iTrial2)
%            end
           if ~isnan(vn) && vn >= 0.3
               %mi = vindn(randi(length(vindn)));
               mi = vindn;
            perCell(gid).v_all(end+1) = vn;
            prev = perCell(gid).vind_all;
            perCell(gid).vind_all = [prev, mi];
            %perCell(gid).vind_all(end+1) = mi;
           end
       end
   end
   
   if length(perCell(gid).vind_all) > 30
       hc = histcounts(perCell(gid).vind_all, 1:5);
       mv = max(hc);
       mi = find(hc == mv);
       %mi = mi(randi(length(mi)));
       total_vind_all = [total_vind_all, mi];
   end
end


total_hc = histcounts(total_vind_all, 1:5);
total_hc = total_hc ./ sum(total_hc) * 100;
figure
bar(total_hc)
title(sprintf('%s', whose_data));
title(sprintf('%s placemaps\nsession %s\nMin comparisons and YES cell-use and MIN MAX 0.3 correlation\n and any angles match that are MAX-0.1 to MAX+0.1\nOnly correlation visited regions', whose_data, sessionName))

%%
% prob_average = zeros(1,4);
% for gid = 1:maxId
%    hc = histcounts(perCell(gid).vind_all, 1:5);
%    hc = hc ./ sum(hc)
%    if isfinite(hc)
%     prob_average = prob_average + hc;
%    end
% end
% figure
% bar(prob_average ./ maxId)

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


% Switch to load either type of placemap data file
function [placemap, extra] = ml_load_placemap_data(filename, whose_data)
    if strcmpi(whose_data, 'marc')
        [placemap, extra] = ml_load_placemap_data_marc(filename);
    elseif strcmpi(whose_data, 'celia')
        [placemap, extra] = ml_load_placemap_data_celia(filename);
    elseif strcmpi(whose_data, 'simulated')
        [placemap, extra] = ml_load_placemap_data_simulated(filename);
    else
        error('only marc and celia work work work!')
    end
end % function

function [placemap, extra] = ml_load_placemap_data_marc(filename)
        x = load(filename);
        placemap = x.pm.eventMapSmoothed;
        
        % extra will be to use the cell or not use the cell
        
        extra = 1;
end % function

function [placemap, extra] = ml_load_placemap_data_celia(filename)
    x = load(filename);
    placemap = x.tc;
    extra = 1;
end % function

function [placemap, extra] = ml_load_placemap_data_simulated(filename)
    numBins = 20;
    M = zeros(numBins);
    M(1,1) = 1;
    R = bwdist(M);
    placemap = R <= 10;
    
    dist = [50, 10, 30, 10];
    cdist = cumsum(dist);
    %cdist = [0, cdist(1:end-1)];
    x = zeros(1, 100);
    xp = 1;
    for k = 1:4
        x(xp:cdist(k)) = k;
        xp = cdist(k);
    end
    i = randi(100);
    j = x(i);
    extra = j;
    placemap = rot90(placemap, j-1);
    placemap = double(placemap);
end % function

% Switch to use either of our datasets
function [placemapFilenames] = ml_nlx_dir_placemaps(trialFolder, whose_data)
    if strcmpi(whose_data, 'marc')
        placemapFilenames = ml_nlx_dir_placemaps_marc(trialFolder);
    elseif strcmpi(whose_data, 'celia') || strcmpi(whose_data, 'simulated')
        placemapFilenames = ml_nlx_dir_placemaps_celia(trialFolder);
    else
        error('only marc and celia work work work!')
    end
end % function
    
function [placemapFilenames] = ml_nlx_dir_placemaps_marc(trialFolder)
    % Get all of the regular cluster files. Do not keep autosave.clusters or
    % anything else that is not like TT#.clusters.
    files = dir(fullfile(trialFolder, 'placemaps_shrunk', 'pm_*.mat')); % We differ here
    keep = zeros(1, length(files));
    for i = 1:length(files)
        if regexp(files(i).name, '^(pm_)\d+(.mat)$') & files(i).isdir == 0
            keep(i) = 1;
        else
            keep(i) = 0;
        end
    end
    files(~keep) = [];
    
    placemapFilenames = cellfun(@(x)(fullfile(trialFolder, 'placemaps_shrunk', x)), {files.name}, 'UniformOutput', false);
end % function

function [placemapFilenames] = ml_nlx_dir_placemaps_celia(trialFolder)
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
