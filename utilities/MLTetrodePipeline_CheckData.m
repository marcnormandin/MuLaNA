% Check the validity of the t-files because of the issue with 32 vs 64 bit'
close all
clear all
clc

pipe = MLTetrodePipeline_v2('pipeline_config.json')

for iSession = 1:pipe.experiment.numSessions
    session = pipe.experiment.session{iSession};
    fprintf('Processing session ( %s )\n', session.name);
    
    % Load the position information for the session
    nvtFilename = fullfile(session.rawFolder, 'VT1.nvt');
    [nlxNvtTimeStamps_mus, ExtractedX, ExtractedY, ExtractedAngle, Targets, Points, Header] = Nlx2MatVT(  nvtFilename, [1, 1, 1, 1, 1, 1], 1, 1, 1 );

    
    tfiles = session.tfiles_filename_full;
    numSingleUnits = length(tfiles);
    for iUnit = 1:numSingleUnits
        tFilename = fullfile(session.rawFolder, tfiles{iUnit});
        
        spikeTimes_mus_32bit = ml_nlx_load_mclust_spikes_as_mus(tFilename, 32);
        is32BitValid = ml_nlx_mclust_spiketimes_are_valid(nlxNvtTimeStamps_mus, spikeTimes_mus_32bit);

        spikeTimes_mus_64bit = ml_nlx_load_mclust_spikes_as_mus(tFilename, 64);
        is64BitValid = ml_nlx_mclust_spiketimes_are_valid(nlxNvtTimeStamps_mus, spikeTimes_mus_64bit);
        
        % Load the tfile
        figure('Name', sprintf('%s, %s', session.name, tFilename))
        
        subplot(3,1,1)
        plot(1:length(nlxNvtTimeStamps_mus), nlxNvtTimeStamps_mus, 'k.')

        subplot(3,1,2)
        plot(1:length(spikeTimes_mus_32bit), spikeTimes_mus_32bit, 'r.')
        if is32BitValid
            title('32 bit is VALID')
        else
            title('32 bit INVALID')
        end
        
        subplot(3,1,3)
        plot(1:length(spikeTimes_mus_64bit), spikeTimes_mus_64bit, 'b.')
        if is64BitValid
            title('64 bit is VALID')
        else
            title('64 bit is INVALID')
        end
    end
end
