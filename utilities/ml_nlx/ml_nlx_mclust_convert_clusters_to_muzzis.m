function ml_nlx_mclust_convert_clusters_to_muzzis(mclustClustersFilename, outputMuzzisFilename)

    data = load(mclustClustersFilename, '-mat');

    Muzzio_Colours = data.MClust_Colors;
    numClusters = length(data.MClust_Clusters);

    Muzzio_Clusters = {};
    for iCluster = 1:numClusters
        Muzzio_Clusters{iCluster} = data.MClust_Clusters{iCluster};
    end

    save(outputMuzzisFilename, 'Muzzio_Clusters', 'Muzzio_Colours', '-mat');
end