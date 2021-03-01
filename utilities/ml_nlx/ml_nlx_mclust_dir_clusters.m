function [clusterFiles] = ml_nlx_mclust_dir_clusters(folder)
% Returns a 'dir' result for MClust cluster files that have the standard
% names like TT4.clusters. This is used so that we can filter out odd names
% like TT4hull_maybe.clusters.

    % Get all of the regular cluster files. Do not keep autosave.clusters or
    % anything else that is not like TT#.clusters.
    clusterFiles = dir(fullfile(folder, '*.clusters'));
    keep = zeros(1, length(clusterFiles));
    for i = 1:length(clusterFiles)
        if regexp(clusterFiles(i).name, '^(TT)\d(.clusters)$')
            keep(i) = 1;
        else
            keep(i) = 0;
        end
    end
    clusterFiles(~keep) = [];
    %numClusterFiles = length(clusterFiles);
end % function
