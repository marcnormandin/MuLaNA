function [xMax_px, yMax_px] = ml_sim_nlx_nvt_save(timestamps_ms, x_cm, y_cm, arena_width_cm, arena_height_cm, video_width_px, video_height_px, outputFilename)
    %                           FieldSelectionFlags(1): Timestamps
    %                           FieldSelectionFlags(2): Extracted X
    %                           FieldSelectionFlags(3): Extracted Y
    %                           FieldSelectionFlags(4): Extracted Angle
    %                           FieldSelectionFlags(5): Targets
    %                           FieldSelectionFlags(6): Points
    %                           FieldSelectionFlags(7): Header

    fieldSelectionFlags = [1, 1, 1, 0, 0, 0, 1];

    % Since which scale we can use
    f1 = floor(video_width_px / arena_width_cm);
    f2 = floor(video_height_px / arena_height_cm);
    f = min([f1, f2]);

    % Convert to microseconds for nlx
    timestamps_mus = timestamps_ms * 1000.0;  % ms to microseconds

    % Scale and convert to pixels
    x = x_cm * f;
    y = y_cm * f;
    x = round(x);
    y = round(y);

    % Used by the ROI code to make them automatically.
    xMax_px = arena_width_cm * f;
    yMax_px = arena_height_cm * f;
    
    % Eliminate any points whose pixel values are invalid
    badi = [];
    badi = union(badi, find(x < 0));
    badi = union(badi, find(x >= video_width_px));
    badi = union(badi, find(y < 0));
    badi = union(badi, find(y >= video_height_px));
    x(badi) = [];
    y(badi) = [];
    timestamps_mus(badi) = [];

    % Arrays must be 1xN
    x = reshape(x, 1, numel(x));
    y = reshape(y, 1, numel(y));
    timestamps_mus = reshape(timestamps_mus, 1, numel(timestamps_mus));

    % Create a header
    header = ml_sim_nlx_nvt_header(video_width_px, video_height_px);

    Mat2NlxVT(outputFilename, 0, 1, [], fieldSelectionFlags, timestamps_mus, x, y, [], [], [], header);

end % function

