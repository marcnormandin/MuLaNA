function [r] = ml_cai_dlc_get_h5_filenames(containerFolder, filenamePrefix)

% This returns an array of structures containing information for matching
% h5 files, and it is sorted by the sequence number of the file.
%
% This is meant to be used for files like
% behavCam1DLC_resnet50_MODEL.h5
% behavCam2DLC_resnet50_MODEL.h5
% etc.

    str1 = sprintf('^(%s)([0-9]+)(.+)(.h5)$', filenamePrefix);
    searchAllSubFolders = false;

    results = ml_dir_regexp_files(containerFolder, str1, searchAllSubFolders);
    r = [];
    for i=1:length(results)
        %fprintf('%s\n', results{i});
        % Full filename (includes path)
        ffn = results{i};

        str2 = sprintf('^(%s)([0-9]+)(.+)', filenamePrefix);

        [filepath, filename, ~] = fileparts(ffn);
        %tmp = 

        [mat, tok, ext] = regexp(filename, str2, 'match', 'tokens', 'tokenExtents');
        t = tok{1};
        r(i).prefix = t{1};
        r(i).num = t{2};
        r(i).dlcTag = t{3};
        r(i).filename = ffn;
    end
    T = struct2table(r);
    sortedT = sortrows(T, 'num');
    r = table2struct(sortedT);

end % function