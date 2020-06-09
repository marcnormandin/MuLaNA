function [fixed] = ml_nlx_nvt_fix_extracted_array(nlx_vt_extracted_array)
PARAM_WS=15; % How many points to smooth over

% All of the indices that we will work on
allIndices = 1:length(nlx_vt_extracted_array);

% Find the indices that are definitely bad
badIndices = find(nlx_vt_extracted_array == 0);

% Find indices that are probably good
goodIndices = sort(setdiff(allIndices, badIndices));

% Create a temporary array because we need to set the bad values to NAN
temp = nlx_vt_extracted_array;
temp(badIndices) = nan;

% Use the good values for the interpolation
interp_data = interp1(goodIndices, temp(goodIndices), allIndices);

% Now smooth the points
smoothed_data = movmean(interp_data, PARAM_WS);

% Some points (near the ends) can be NAN, so we just extend with the
% closest constant value. We find the indices of all the NAN and form
% them into groups since we may have more than one.
nanIndices = find(isnan(smoothed_data)==1);

fixed = smoothed_data;

if isempty(nanIndices) == 0
    % There will be one group id for each nan index showing what group
    % the nan index belongs to (dangling?)
    nanClasses = ml_util_group_points(nanIndices, 1);

    % In the future the group ids may not start at 1, so get them explicitly
    groupIds = sort(unique(nanClasses));

    numGroups = length(groupIds);
    fprintf('Found %d groups of NAN.\n', numGroups);

    for iGroup = 1:numGroups
        gs = find(nanClasses == groupIds(iGroup), 1, 'first');
        fprintf('Just found gs\n');
        disp(gs)
        % There may not be any nans.
        if isempty(gs)
            continue
        end

        gstart = nanIndices(gs);


        gend = nanIndices(find(nanClasses == groupIds(iGroup), 1, 'last'));

        if gstart == 1
            % need a right point
            fixed(gstart:gend) = fixed(gend+1); % changed from fixed(gend+1)
        elseif gend == length(fixed)
            % need a left point
            fixed(gstart:gend) = fixed(gstart-1);
        else % this shouldn't happen, but lets be same. Take average for interior point
            avg = (fixed(gstart-1) + fixed(gend+1)) / 2;
            fixed(gstart:gend) = avg;
        end
    end
end

% The values need to be integers for NLX NVT files.
% Floor the value so we don't go higher (unlikely) then what the video
% file supports.
%fixed = floor(fixed);

end
