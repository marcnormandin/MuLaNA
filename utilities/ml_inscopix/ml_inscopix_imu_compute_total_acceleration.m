function [regular_timestamps_s, regular_ax, regular_ay, regular_az, regular_totalAcceleration, imuFs] = ml_inscopix_imu_compute_total_acceleration( imuData )
    imuFs = 50; % Sampling rate of the IMU in Hz

    numSamples = length(imuData.IMU_Time_s);
    timestamps_s = imuData.IMU_Time_s;
    
    % Find the values that we need to fix. We assume that the timestamps will
    % always be valid.
    sampleIsInvalid = false(1,numSamples);
    fieldNames = {'Acc_x', 'Acc_y', 'Acc_z'};
    for iField = 1:length(fieldNames)
       ind = find(~isfinite(imuData.(fieldNames{iField})));
       sampleIsInvalid(ind) = true;
    end
    ax = imuData.Acc_x;
    ay = imuData.Acc_y;
    az = imuData.Acc_z;

    % Interpolate the invalid values
    ax(sampleIsInvalid) = interp1(timestamps_s(~sampleIsInvalid), ax(~sampleIsInvalid), timestamps_s(sampleIsInvalid));
    ay(sampleIsInvalid) = interp1(timestamps_s(~sampleIsInvalid), ay(~sampleIsInvalid), timestamps_s(sampleIsInvalid));
    az(sampleIsInvalid) = interp1(timestamps_s(~sampleIsInvalid), az(~sampleIsInvalid), timestamps_s(sampleIsInvalid));

    % The sample rate isn't actually constant (almost) so create regular samples
    regular_timestamps_s = timestamps_s(1):(1/imuFs):timestamps_s(end);
    regular_ax = interp1(timestamps_s, ax, regular_timestamps_s);
    regular_ay = interp1(timestamps_s, ay, regular_timestamps_s);
    regular_az = interp1(timestamps_s, az, regular_timestamps_s);

    regular_totalAcceleration = sqrt( regular_ax.^2 + regular_ay.^2 + regular_az.^2 );    
end % function