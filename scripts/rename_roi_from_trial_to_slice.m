% To improve the nomenclature the trial_#_arenaroi.mat were renamed to
% slice_#_arenaroi.mat because some slices are discarded trials, etc.

% Set this to the outermost parent folder that contains subfolders the
% trial_#_arenaroi.mat
containerFolder = 'T:\Shamu_two_contexts_CA1\tetrodes\recordings';

s = '^(trial_)\d+(_arenaroi.mat)$';

roiFilenames = ml_dir_regexp_files(containerFolder, s, true)
for iFile = 1:length(roiFilenames)
   oldFilename = roiFilenames{iFile};
   [filepath, name, ext] = fileparts(oldFilename);
   
   newFilename = fullfile(filepath, sprintf('%s%s', strrep(name, 'trial', 'slice'), ext));
   
   fprintf('%s -> %s\n', roiFilenames{iFile}, newFilename)

   if ~movefile(oldFilename, newFilename)
       error('Error renaming %s to %s\n', oldFilename, newFilename);
   end
end
