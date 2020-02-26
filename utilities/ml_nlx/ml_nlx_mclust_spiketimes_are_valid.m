function isValid = ml_nlx_mclust_spiketimes_are_valid(nlxNvtTimeStamps_mus, mclustTimeStamps_mus)

% Check that the neuralynx timestamps are valid
if any(diff(nlxNvtTimeStamps_mus) < 0)
    error('The Neuralynx timestamps are not montonically increasing!\n');
end

isValid = true;

% The mclust timestamps must be monotonically increasing
if any(diff(mclustTimeStamps_mus) < 0)
    isValid = false;
    return
end

if min(mclustTimeStamps_mus) < min(nlxNvtTimeStamps_mus)
    isValid = false;
    return
end

if max(mclustTimeStamps_mus) > max(nlxNvtTimeStamps_mus)
    isValid = false;
    return
end

end
