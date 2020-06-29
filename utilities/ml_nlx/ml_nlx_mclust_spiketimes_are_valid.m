function [isValid] = ml_nlx_mclust_spiketimes_are_valid(nlxNvtTimeStamps_mus, mclustTimeStamps_mus, verbose)

    isValid = true;

    % Check that the neuralynx timestamps are valid
    if any(diff(nlxNvtTimeStamps_mus) < 0)
        if verbose
            fprintf('The Neuralynx timestamps are not montonically increasing!\n');
        end
        isValid = false;
    end


    % The mclust timestamps must be monotonically increasing
    if any(diff(mclustTimeStamps_mus) < 0)
        if verbose
            fprintf('The MClust timestamps are not montonically increasing!\n');
        end
        isValid = false;
    end

    if min(mclustTimeStamps_mus) < min(nlxNvtTimeStamps_mus)
        if verbose
            fprintf('A spike comes before the start of the session!\n');
        end
        isValid = false;
    end

    if max(mclustTimeStamps_mus) > max(nlxNvtTimeStamps_mus)
        if verbose
            fprintf('A spike comes after the end of the session!\n');
        end
        isValid = false;
    end
end
