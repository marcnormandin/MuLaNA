function ml_two_contexts_plot_averaged_combined_orientation(pc, contexts)

% contexts must be "all" or "within"

% This code make the orientation plot averaged across days
% It has to be so specific and clunky because some mice
% have more than 3 days, and we have to specify unique ones for each mouse.

% Load the project settings
if isempty(pc)
    pcFilename = fullfile(pwd, 'project_config.json');
    if ~isfile(pcFilename)
        error('Missing file (%s).', pcFilename);
    end
    pc = jsondecode(fileread(pcFilename));
end

% Feature rich analysis folder
frFolder = fullfile(pc.analysisFolder, 'feature_rich');

% Feature poor analysis folder
fpFolder = fullfile(pc.analysisFolder, 'feature_poor');

% We can determine whether the mouse is feature_rich or feature_poor
% by looking in the analysis directories
tinimice = {'K1_CA1', 'AK42_CA1', 'AK74_CA1', 'JJ9_CA1', 'MG1_CA1'};

% We will average over 3 days
numDays = 3;
avgOrientation = zeros(numDays,4,length(tinimice));
for iMouse = 1:length(tinimice)
   fprintf('Loading orientation statistics for ( %s )\n', tinimice{iMouse});
   
   if exist(fullfile(frFolder, tinimice{iMouse}), 'dir')
       inputFolder = fullfile(frFolder, tinimice{iMouse});
   elseif exist(fullfile(fpFolder, tinimice{iMouse}), 'dir')
       inputFolder = fullfile(fpFolder, tinimice{iMouse});
   else
       error("Can't find the mouse in either the feature rich or feature poor folder.");
   end
   
   
   if strcmpi(contexts,'all')
        tmp = load(fullfile(inputFolder, 'best_fit_orientations_all_contexts.mat'));
        bfo = tmp.best_fit_orientations_all_contexts;
   elseif strcmpi(contexts, 'within')
        tmp = load(fullfile(inputFolder, 'best_fit_orientations_within_contexts.mat'));
        bfo = tmp.best_fit_orientations_within_contexts;
   else
       error('contexts parameter must be all or within');
   end
   
   if strcmp(tinimice{iMouse}, 'K1_CA1') || strcmp(tinimice{iMouse}, 'AK42_CA1') || strcmp(tinimice{iMouse}, 'AK74_CA1') || strcmp(tinimice{iMouse}, 'JJ9_CA1') 
       x = bfo(1:3,:);
   elseif strcmp(tinimice{iMouse}, 'MG1_CA1')
       % analyzed 7,8,9,10,11
       % days 8,9,10 since day 7 was first day after the problem
       x = bfo(2:4,:);
   else
       error('Invalid mouse')
   end
   disp(x)
   
   avgOrientation(:,:,iMouse) = x;
end

% Compute over the 3rd dimension which is the mouse
xmean = mean(avgOrientation,3)';
xstd = std(avgOrientation,0, 3)';

%h = figure('Name', sprintf('Averaged Best Fit Orientations for Tinimice'), 'Position', get(0,'Screensize'));
h = figure('Name', sprintf('Averaged Best Fit Orientations for Tinimice'));

y1 = xmean;
hBar = bar(y1,1);
hBar(1).FaceColor = [0, 0, 0.33];
hBar(1).FaceAlpha = 0.6;
hBar(1).LineWidth = 2;

hBar(2).FaceColor = [0, 0, 0.66];
hBar(2).FaceAlpha = 0.4;
hBar(2).LineWidth = 2;

hBar(3).FaceColor = [0, 0, 0.99];
hBar(3).FaceAlpha = 0.2;
hBar(3).LineWidth = 2;

hold on
ctr = [];
ydt=[];
err1=[];
for k1 = 1:size(xmean,2)
    ctr(k1,:) = bsxfun(@plus, hBar(k1).XData, hBar(k1).XOffset');
    ydt(k1,:) = hBar(k1).YData;
    err1(k1,:) = xstd(:,k1);
end
hold on
errorbar(ctr, ydt, err1, 'k.', 'linewidth', 2) 
legend({'Day 1', 'Day 2', 'Day 3'});
grid on
grid minor
set(gca,'XTickLabel',{['0' char(176)], ['90' char(176)], ['180' char(176)], ['270' char(176)]})
%xlabel('Orientation [deg]')
ylabel('Proportion Best Fit', 'fontweight', 'bold')
title(sprintf('Averaged (%d days) Best Fit Orientations (%s contexts)\n%s\nSubjects: %s', numDays, contexts, datetime, strjoin(tinimice, ', ')), 'interpreter', 'none')

    
% Save the figure to the main analysis folder since it involves all of the
% mice.
outputFolder = pc.analysisFolder;

fnPrefix = sprintf('avg_best_fit_orientations_%s_contexts', contexts);

F = getframe(h);
imwrite(F.cdata, fullfile(outputFolder, sprintf('%s.png', fnPrefix)), 'png')
savefig(h, fullfile(outputFolder, sprintf('%s.fig', fnPrefix)))
saveas(h, fullfile(outputFolder, sprintf('%s.svg', fnPrefix)), 'svg')
print('-painters', '-depsc', fullfile(outputFolder,sprintf('%s.eps', fnPrefix)))

close(h);

end % function
