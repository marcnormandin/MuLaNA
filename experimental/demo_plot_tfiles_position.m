close all
clear all
clc

pipeCfgFilename = fullfile(pwd, 'pipeline_config.json');

tstart = tic;

%subjects = {'MG1_DH', 'K1', 'AK42', 'AK74', 'JJ9'};
%subjects = {'AK42', 'AK74', 'JJ9'};
%task='object_task_test';
%'HG_OLD1_OTASKT'};

homework = [];
% homework(1).subjectName = 'MGDH1_TEST2';
% homework(1).experiment = 'MG1_Object_Task_Test';
% homework(2).subjectName = 'MGDH1_TEST2';
% homework(2).experiment = 'MG1_Object_Task_HabTrials';
% 
% homework(1).subjectName = 'HG_OLD1';
% homework(1).experiment = 'object_task';

% homework(1).subjectName = 'MGDH1_OBCT';
% homework(1).experiment = 'object_task_consecutive_trials';

%homework(1).subjectName = 'AK42';
%homework(1).experiment = 'chengs_task_2c';

homework(1).subjectName = 'K1';
homework(1).experiment = 'chengs_task_2c';

for iHomework = 1:length(homework)
    subjectName = homework(iHomework).subjectName;
    experiment = homework(iHomework).experiment;
    
    recordingsParentFolder = fullfile(pwd, subjectName, 'recordings', experiment);
    analysisParentFolder = fullfile(pwd, subjectName, 'analysis_20200221', experiment);

    pipe = MLTetrodePipeline( pipeCfgFilename, recordingsParentFolder, analysisParentFolder);
    
    
    iSession = 3;
    session = pipe.experiment.session{iSession};
    numCells = session.num_tfiles;
    c = distinguishable_colors(numCells);
    for iTrial = 1:session.num_trials_to_use
        figure('name', sprintf('Trial %d', iTrial))
        for iCell = 1:numCells
            tmp = load( fullfile(session.analysisFolder, 'placemaps_rectangle', sprintf('%s_%d_mltetrodeplacemaprect.mat', session.tfiles_filename_prefixes{iCell}, iTrial)) );
            d = tmp.mltetrodeplacemap;
            p = 5; q = 5; k = iCell;

            bx(k) = subplot(p,q,k);
            %plot(d.x, d.y, 'k.-')
            hold on
            %plot(d.spike_x, d.spike_y, 'bo', 'markerfacecolor', 'b', 'markersize', 10)
            plot(d.spike_x(d.passedSpeedSpikei), d.spike_y(d.passedSpeedSpikei), 'o', 'markerfacecolor', c(iCell,:), 'markersize',4)
            grid on
            grid minor
            xlabel('x')
            ylabel('y')
            axis equal tight
            axis off
            title(sprintf('%s', session.tfiles_filename_prefixes{iCell}), 'interpreter', 'none')
        end % iCell
        linkaxes(bx, 'xy')
    end
end
