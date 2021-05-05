function [imuData] = ml_inscopix_imu_read_csv(fn)
    if ~isfile(fn)
        error('The file (%s) does not exist.', fn);
    end
    
    % Read the header
    fid = fopen(fn, 'r');
    header = fgetl(fid);
    fclose(fid);
    columnNames = split(header, ',');

    % Remove the unfilled entries
    columnNames(8:end) = [];

    % Fix the column names so that we can use them in MATLAB
    numColumns = length(columnNames);
    for i = 1:numColumns
        s = columnNames{i};
        s = strrep(strtrim(s), ' ', '_');
        s = strrep(s, '(', '');
        s = strrep(s, ')', '');

        columnNames{i} = s;
    end

    data = csvread(fn, 2);

    imuData = [];
    for iColumn = 1:numColumns
        imuData.(columnNames{iColumn}) = data(:,iColumn);
    end
end