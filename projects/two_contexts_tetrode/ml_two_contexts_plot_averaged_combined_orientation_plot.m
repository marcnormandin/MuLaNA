function ml_two_contexts_plot_averaged_combined_orientation_plot(pc)

% This code make the orientation plot averaged across days
% It has to be so specific and clunky because some mice
% have more than 3 days, and we have to specify unique ones for each mouse.

% Load the project settings
% pcFilename = fullfile(pwd, 'project_config.json');
% if ~isfile(pcFilename)
%     error('Missing file (%s).', pcFilename);
% end
% pc = jsondecode(fileread(pcFilename));

% Feature rich analysis folder
frFolder = fullfile(pc.analysisFolder, 'feature_rich');

% Feature poor analysis folder
fpFolder = fullfile(pc.analysisFolder, 'feature_poor');

% We can determine whether the mouse is feature_rich or feature_poor
% by looking in the analysis directories
tinimice = {'K1_CA1', 'AK42_CA1', 'AK74_CA1', 'JJ9_CA1', 'MG1_CA1'};

% We will average over 3 days
numDays = 3;
avgOrientation = zeros(numDays,4);
for iMouse = 1:length(tinimice)
   fprintf('Loading orientation statistics for ( %s )\n', tinimice{iMouse});
   
   if exist(fullfile(frFolder, tinimice{iMouse}), 'dir')
       inputFolder = fullfile(frFolder, tinimice{iMouse});
   elseif exist(fullfile(fpFolder, tinimice{iMouse}), 'dir')
       inputFolder = fullfile(fpFolder, tinimice{iMouse});
   else
       error("Can't find the mouse in either the feature rich or feature poor folder.");
   end
   
   tmp = load(fullfile(inputFolder, 'best_fit_orientations_all_contexts.mat'));
   bfo = tmp.best_fit_orientations_all_contexts;
   
   if strcmp(tinimice{iMouse}, 'K1_CA1') || strcmp(tinimice{iMouse}, 'AK42_CA1') || strcmp(tinimice{iMouse}, 'AK74_CA1') || strcmp(tinimice{iMouse}, 'JJ9_CA1') 
       x = bfo(1:3,:);
   elseif strcmp(tinimice{iMouse}, 'MG1_CA1')
       % days 8,9,10 since day 7 was first day after the problem
       x = bfo(2:4,:);
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

outputFolder = pc.analysisFolder;

F = getframe(h);
imwrite(F.cdata, fullfile(outputFolder, 'avg_best_fit_orientations_all_contexts.png'), 'png')
savefig(h, fullfile(outputFolder, 'avg_best_fit_orientations_all_contexts.fig'));
saveas(h, fullfile(outputFolder, 'avg_best_fit_orientations_all_contexts.svg'), 'svg');
print('-painters', '-depsc', fullfile(outputFolder,'avg_best_fit_orientations_all_contexts.eps'))
close(h);

end % function
