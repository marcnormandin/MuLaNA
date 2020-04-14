close all
clear all
clc

tinimice = {'K1', 'AK42', 'AK74', 'JJ9', 'MG1_DH'};
%%
% for iMouse = 1:length(tinimice)
%     run(sprintf('%s_pipeline_run_v3.m', tinimice{iMouse}));
% end

%%
numDays = 3;
avgOrientation = zeros(numDays,4);
for iMouse = 1:length(tinimice)
   fprintf('Loading orientation statistics for ( %s )\n', tinimice{iMouse});
   inputFolder = fullfile(pwd, tinimice{iMouse}, 'analysis_20200214_morebins_method2', 'chengs_task_2c');
   tmp = load(fullfile(inputFolder, 'best_fit_orientations_all_contexts.mat'));
   bfo = tmp.best_fit_orientations_all_contexts;
   %disp(bfo)
   
   if strcmp(tinimice{iMouse}, 'K1') || strcmp(tinimice{iMouse}, 'AK42') || strcmp(tinimice{iMouse}, 'AK74') || strcmp(tinimice{iMouse}, 'JJ9') 
       x = bfo(1:3,:);
   elseif strcmp(tinimice{iMouse}, 'MG1_DH')
       x = bfo(4:6,:);
   else
       error('Invalid mouse')
   end
   disp(x)
   
   avgOrientation = avgOrientation + x;
end
avgOrientation = avgOrientation ./ length(tinimice);

h = figure('Name', sprintf('Averaged Best Fit Orientations for Tinimice'), 'Position', get(0,'Screensize'));
bar([0, 90, 180, 270], avgOrientation');
hold on 
grid on
title(sprintf('Averaged (%d days) Best Fit Orientations for Tinimice\n%s\nSubjects: %s', numDays, datetime, strjoin(tinimice, ', ')), 'interpreter', 'none')
ylabel('Proportion Best Fit')
xticklabels({['0' char(176)], ['90' char(176)], ['180' char(176)], ['270' char(176)]});
outputFolder = pwd;
F = getframe(h);
imwrite(F.cdata, fullfile(outputFolder, 'avg_best_fit_orientations_all_contexts.png'), 'png')
savefig(h, fullfile(outputFolder, 'avg_best_fit_orientations_all_contexts.fig'));
saveas(h, fullfile(outputFolder, 'avg_best_fit_orientations_all_contexts.svg'), 'svg');
print('-painters', '-depsc', fullfile(outputFolder,'avg_best_fit_orientations_all_contexts.eps'))
close(h);
