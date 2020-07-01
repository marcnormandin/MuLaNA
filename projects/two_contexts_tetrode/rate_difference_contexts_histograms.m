close all
clear all
clc

project = ml_util_json_read('project_config.json');

fl = dir(fullfile(project.analysisFolder, '**', 'rate_difference_matrices.mat'));

%iFile = 1;
sc = [];
dc = [];
for iFile = 1:length(fl)
    f = fl(iFile);
    fn = fullfile(f.folder, f.name);
    [scn, dcn] = process_matrix(fn);
    sc = [sc, scn];
    dc = [dc, dcn];
end

figure
subplot(1,2,1)
histogram(sc, 'normalization', 'probability')
title('Same Context')
grid on

subplot(1,2,2)
histogram(dc, 'normalization', 'probability')
title('Different Context');
grid on

function [sc, dc] = process_matrix(fn)
    data = load(fn);
    cids = data.cids;
    tids = data.tids;
    data = data.rate_difference_matrices_per_cell;
    numCells = length(data);
    
    sc = [];
    dc = [];
    for iCell = 1:numCells
        m = data(iCell);
        m = m{1};
        numTrials = size(m,1);
        for iTrial1 = 1:numTrials
            for iTrial2 = iTrial1:numTrials
                c1 = cids(iTrial1);
                c2 = cids(iTrial2);

                if c1 == c2
                    sc(end+1) = m(iTrial1, iTrial2);
                else
                    dc(end+1) = m(iTrial1, iTrial2);
                end
            end
        end
    end
end % function

    

    
%end