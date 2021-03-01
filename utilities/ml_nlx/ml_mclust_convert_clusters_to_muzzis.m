function ml_mclust_convert_clusters_to_muzzis(mclustClusterFilename, muzzioClusterFilename)
    % Basically a direct copy from a .clusters file to a new .muzzis file.
    % We can't just use copyfile because the structures were renamed.
    
    % Load the MClust '.clusters' file
   data = load(mclustClusterFilename, '-mat');
   numClusters = length(data.MClust_Clusters);

    % Make a direct copy.
    Muzzio_Colours = data.MClust_Colors;
    Muzzio_Clusters = {};
    for iCluster = 1:numClusters
        Muzzio_Clusters{iCluster} = data.MClust_Clusters{iCluster};
    end

    ofn = muzzioClusterFilename;

    if isfile(ofn)
        delete(ofn)
    end
    fprintf('Saving file (%s)\n', ofn);
    save(ofn, 'Muzzio_Clusters', 'Muzzio_Colours', '-mat');

%     % Create the FD directory if it doesnt already exist
%     fdDirectory = fullfile(outputFolder, 'FD');
%     if ~exist(fdDirectory, 'dir')
%         mkdir(fdDirectory);
%     end
end % function
