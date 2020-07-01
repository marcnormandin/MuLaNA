close all
clear all
clc

project = ml_util_json_read('project_config.json');

fl = dir(fullfile(project.analysisFolder, '**', 'bfo_180_total.mat'));

%iFile = 1;
sc = [];
dc = [];
ac = [];
for iFile = 1:length(fl)
    f = fl(iFile);
    fn = fullfile(f.folder, f.name);
    [scn, dcn, acn] = process_scores(fn);
    sc = [sc, scn];
    dc = [dc, dcn];
    ac = [ac, acn];
end

% We need to know the domain to plot
[scx, szy] = compute_cumdist(sc);
[dcx, dcy] = compute_cumdist(dc);
[acx, acy] = compute_cumdist(ac);

figure
plot(scx, szy, 'r-')
hold on
plot(dcx, dcy, 'g-')
plot(acx, acy, 'b-')
xlabel('Similarity Score')
ylabel('Cumulative Proportion')
title('All data used')
grid on
legend('Same Context', 'Different Context', 'All Contexts')
axis square

xlim([-1,1])


function [sc, dc, ac] = process_scores(fn)
    data = load(fn);
    total = data.total;
    sc = total.v_same;
    dc = total.v_different;
    ac = total.v_all;
end % function

function [uz,cz] = compute_cumdist(z)
    uz = sort(unique(z));
    cz = zeros(1,length(uz));
    for i = 1:length(uz)
        cz(i) = sum( z <= uz(i) );
    end
    cz = cz ./ length(z);
end
    

    
%end