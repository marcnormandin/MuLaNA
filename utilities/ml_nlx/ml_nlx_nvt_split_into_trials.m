function [trial] = ml_nlx_nvt_split_into_trials( nvtFilename, nvt_file_trial_separation_threshold_s )
    % Check that the inputs are fine
    if ~isfile( nvtFilename )
        error('The required file (%s) does not exist.\n', nvtFilename);
    end
    if nvt_file_trial_separation_threshold_s <= 0
        error('The trial separation threshold must be >= 0, but is (%d).', nvt_file_trial_separation_threshold_s);
    end
    
    %[TimeStamps_mus, ExtractedX, ExtractedY, ExtractedAngle, Targets, Points, Header] = Nlx2MatVT(  nvtFilename, [1, 1, 1, 1, 1, 1], 1, 1, 1 );
    [TimeStamps_mus, ExtractedX, ExtractedY, ExtractedAngle, Targets, Points, Header] = ml_nlx_nvt_load( nvtFilename );
    
    inds = ml_nlx_nvt_find_trial_indices(TimeStamps_mus, nvt_file_trial_separation_threshold_s);

    numTrials = size(inds,2);
    trial = cell(numTrials,1);
    for i = 1:numTrials
        p = inds(1,i);
        q = inds(2,i);

        trial{i}.numSamples = (q-p)+1;

        trial{i}.startIndex = p;
        trial{i}.stopIndex = q;
        trial{i}.timeStamps_mus = TimeStamps_mus(p:q);
        trial{i}.extractedX = ExtractedX(p:q);
        trial{i}.extractedY = ExtractedY(p:q);
        trial{i}.extractedAngle = ExtractedAngle(p:q);
        trial{i}.targets = Targets(:,p:q);
        trial{i}.points = Points(:,p:q);
        trial{i}.header = Header; % full header
        trial{i}.trial_id = i;
    end
end
