function [data] = ml_singleunits_load_nlx_mclust( nvtFilename, tfileFolder )
    % This function loads all of the t-files in the given folder, and uses
    % the neuralynx nvt file in order to determine the bits of the tfiles
    % so that they are loaded correctly.
    [nlxNvtTimeStamps_mus, ~, ~, ~, ~, ~, ~] = ml_nlx_nvt_load( nvtFilename );

    fl = dir(fullfile(tfileFolder, 'TT*.t'));
    tfiles = { fl.name };
    data = [];

    data.numSingleUnits = length(tfiles);
    data.timeUnits = 'milliseconds';
    data.activityUnits = 'spikes';
    data.filterType = 'mclust';

    for iFile = 1:length(tfiles)
        singleUnit.name = tfiles{iFile};
        fprintf('Processing tfile ( %s )\n', singleUnit.name);

        singleUnit.t = [];
        singleUnit.activity = [];
        try
            spikeTimes_mus = ml_nlx_load_mclust_spikes_as_mus(nlxNvtTimeStamps_mus, fullfile(tfileFolder, singleUnit.name), -1);
            timeScaleFactor = ml_util_timeunit_conversion_scalefactor( 'microseconds', data.timeUnits );
            singleUnit.t = spikeTimes_mus * timeScaleFactor;
            singleUnit.activity = ones(size(singleUnit.t));
            singleUnit.isValid = true;
        catch e
            singleUnit.isValid = false;
        end
        
        data.singleUnit(iFile) = singleUnit;
    end
end % function

