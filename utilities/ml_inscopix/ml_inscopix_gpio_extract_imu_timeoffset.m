function [imuOffset_s] = ml_inscopix_gpio_extract_imu_timeoffset(fn)
    if ~isfile(fn)
        error('The file (%s) does not exist. Can not extract the IMU time offset from it.', fn);
    end
    
    T = readtable(fn, 'FileType', 'text');

    ind = find(ismember(T.ChannelName, 'BNC Trigger Input'));
    if isempty(ind)
        error('Unable to find channel BNC Trigger Input');
    end
    
    % Make a subtable for just BNC Trigger Input
    t = T(ind,:);

    % Extract the time when it first turns on (Value == 1).
    ind = find(t.Value(:) == 1, 1, 'first');
    tt = t(ind,:);
    if size(tt,1) ~= 1
        error('Unable to find offset. Check algorithm.');
    end
    imuOffset_s = tt.Time_s_(:);
end % function
