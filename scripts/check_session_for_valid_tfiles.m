close all
clear all
clc

folder = 'T:\Shamu_two_contexts_CA1\tetrodes\recordings\feature_poor\HGY1_CA1\s1';
nvtFullFilename = fullfile(folder, 'VT1.nvt');
%tFilename = fullfile(folder, 'TT5_6.t');
numBits = -1;

tFiles = dir(fullfile(folder, 'TT*.t'));
for iFile = 1:length(tFiles)
    tFilename = fullfile(tFiles(iFile).folder, tFiles(iFile).name);
    [nlxNvtTimeStamps_mus, ExtractedX, ExtractedY, ExtractedAngle,  Targets, Points, Header] = Nlx2MatVT(  nvtFullFilename, [1, 1, 1, 1, 1, 1], 1, 1, 1 );

    try
        spikeTimes_mus = ml_nlx_load_mclust_spikes_as_mus(nlxNvtTimeStamps_mus, tFilename, numBits);
    catch e
        warning(e.getReport())
    end
end
