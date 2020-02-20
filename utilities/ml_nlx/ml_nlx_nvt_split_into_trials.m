function [trial] = ml_nlx_nvt_split_into_trials( nvtFilename, nvt_file_trial_separation_threshold_s )
    [TimeStamps_mus, ExtractedX, ExtractedY, ExtractedAngle, Targets, Points, Header] = Nlx2MatVT(  nvtFilename, [1, 1, 1, 1, 1, 1], 1, 1, 1 );

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
    end
end
