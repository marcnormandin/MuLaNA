close all
clear all
clc

sessionsToUse = [2];

project = ml_util_json_read('project_config.json');

expRich = dir(fullfile(project.dataFeatureRichFolder, '**', 'experiment_description.json'));
miceRich = initMice(expRich, project.analysisFeatureRichFolder);
plot_mice_groups(miceRich, sessionsToUse)

expPoor = dir(fullfile(project.dataFeaturePoorFolder, '**', 'experiment_description.json'));
micePoor = initMice(expPoor, project.analysisFeaturePoorFolder);
plot_mice_groups(micePoor, sessionsToUse)

function plot_mice_groups(mice, sessionsToUse)
    [sc, dc, ac, scx, scy, dcx, dcy, acx, acy] = compute_cumulative_scores(mice, sessionsToUse);
    figure
    plot(scx, scy, 'r-')
    hold on
    plot(dcx, dcy, 'g-')
    plot(acx, acy, 'b-')
    xlabel('Firing Rate Difference')
    ylabel('Cumulative Proportion')
    
    s = join({mice.subjectName}, ' ');
    miceNames = s{1};
    days = sprintf('%d ', sessionsToUse);
    title(sprintf('Mice: %s\n Day(s): %s', miceNames, days), 'interpreter', 'none')
    grid on
    legend('Same Context', 'Different Context', 'All Contexts')
    axis square

    %xlim([-1,1])
    
    
    figure
    histogram(sc, 'FaceColor', 'none', 'normalization', 'probability', 'DisplayStyle', 'stairs')
    hold on
    histogram(dc, 'FaceColor', 'none', 'normalization', 'probability', 'DisplayStyle', 'stairs')
    title(sprintf('Mice: %s\n Day(s): %s', miceNames, days), 'interpreter', 'none')
    legend({'same context', 'different context'})
end


function [mice] = initMice(expList, analysisParentFolder)
    mice = struct('subjectName', [], 'recordingsParentFolder', [], 'analysisParentFolder', []);
    for i = 1:length(expList)
        mice(i).recordingsParentFolder = expList(i).folder;

        s = split(mice(i).recordingsParentFolder, filesep);
        subjectName = s{end};

        mice(i).analysisParentFolder = fullfile(analysisParentFolder, subjectName);
        mice(i).subjectName = subjectName;
    end
end





function [sc, dc, ac, scx, scy, dcx, dcy, acx, acy] = compute_cumulative_scores(mice, sessionsToUse)

sc = [];
dc = [];
ac = [];

% For each exp file
numMice = length(mice);
for iMouse = 1:numMice
    mouse = mice(iMouse);
    
    % Load a pipeline
    pipeCfg = ml_util_json_read( fullfile(pwd, 'pipeline_config.json') );
    pipe = MLTetrodePipeline( pipeCfg, mouse.recordingsParentFolder, mouse.analysisParentFolder);

    for i = 1:length(sessionsToUse)
        session = pipe.Experiment.getSession(sessionsToUse(i));
        
        outputFolder = fullfile(session.getAnalysisDirectory(), pipe.Config.rate_difference_matrices.outputFolder);
        dataFn = fullfile(outputFolder, pipe.Config.rate_difference_matrices.outputMatFilename);
        
        fl = dir(dataFn);
        if length(fl) ~= 1
            error('Found more than one matched file.');
        end
        f = fl(1);
        fn = fullfile(f.folder, f.name);
        
        [scn, dcn, acn] = process_data(fn);
        sc = [sc, scn];
        dc = [dc, dcn];
        ac = [ac, acn];
    end
end

% We need to know the domain to plot
[scx, scy] = compute_cumdist(sc);
[dcx, dcy] = compute_cumdist(dc);
[acx, acy] = compute_cumdist(ac);

% figure
% plot(scx, scy, 'r-')
% hold on
% plot(dcx, dcy, 'g-')
% plot(acx, acy, 'b-')
% xlabel('Similarity Score')
% ylabel('Cumulative Proportion')
% title('All data used')
% grid on
% legend('Same Context', 'Different Context', 'All Contexts')
% axis square
% 
% xlim([-1,1])

end % function


function [sc, dc, ac] = process_data(fn)
    data = load(fn);
    rate_difference_matrices_per_cell = data.rate_difference_matrices_per_cell;
    tids = data.tids;
    cids = data.cids;
    
    sc = [];
    dc = [];
    ac = [];
    
    for iCell = 1:length(rate_difference_matrices_per_cell)
        R = rate_difference_matrices_per_cell{iCell};
        for i = 1:length(tids)
            for j = i+1:length(tids)
                if cids(i) == cids(j)
                    sc(end+1) = R(i,j);
                else
                    dc(end+1) = R(i,j);
                end
                
                ac(end+1) = R(i,j);
            end
        end
    end

end % function

function [uz,cz] = compute_cumdist(z)
    uz = sort(unique(z));
    cz = zeros(1,length(uz));
    for i = 1:length(uz)
        cz(i) = sum( z <= uz(i) );
    end
    cz = cz ./ length(z);
end
