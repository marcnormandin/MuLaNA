function [ts_mus, x_px, y_px, angle_deg, targets, points, header] = ml_nlx_nvt_load(nvtFullFilename)
% This function was written as a interface to the lower level code from
% Neuralynx and because of a strange issue of duplicated data encoutered
% when using the officla NeuraView tool to split a session into mulitple
% trials.

    [nlxNvtTimeStamps_mus, ExtractedX, ExtractedY, ExtractedAngle,  Targets, Points, Header] = Nlx2MatVT(  nvtFullFilename, [1, 1, 1, 1, 1, 1], 1, 1, 1 );
    
    % Remove any duplicated timestamps and store them in ia in ascending
    % order
    [~, ia, ~] = unique(nlxNvtTimeStamps_mus); % ia are the indices into the original array
    
    ts_mus = nlxNvtTimeStamps_mus(ia);
    x_px = ExtractedX(ia);
    y_px = ExtractedY(ia);
    angle_deg = ExtractedAngle(ia);
    targets = Targets(:,ia);
    points = Points(:, ia);
    header = Header;

%     First version that didn't work with the Targets and Points
%     [nlxNvtTimeStamps_mus, ExtractedX, ExtractedY, ExtractedAngle, ~, ~, ~] = Nlx2MatVT(  nvtFullFilename, [1, 1, 1, 1, 1, 1], 1, 1, 1 );
%     % The split data has overlapping duplicates
%     % We need to remove them BECAUSE WHY WOULD IT JUST MAKE SENSE... LOL
%     ts_mus = reshape(nlxNvtTimeStamps_mus, numel(nlxNvtTimeStamps_mus), 1);
%     x_px = reshape(ExtractedX, numel(ExtractedX), 1);
%     y_px = reshape(ExtractedY, numel(ExtractedY), 1);
%     angle_deg = reshape(ExtractedAngle, numel(ExtractedAngle), 1);
%     M = [ts_mus, x_px, y_px, angle_deg];
%     [C, IA, IC] = unique(M, 'rows');
%     
%     M = sortrows(C, 1); % sort by timestamp
%     
%     ts_mus = M(:,1);
%     x_px = M(:,2);
%     y_px = M(:,3);
%     angle_deg = M(:,4);
    
end % function