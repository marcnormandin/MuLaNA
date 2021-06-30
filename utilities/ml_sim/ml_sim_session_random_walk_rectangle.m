% 2021-06-04: I wrote this code to test the path simulation code. The path
% simulation code performs a random walk with intermitent attraction to one
% of the 4 cups so that the paths are more realistic to what we see with
% real data.

% 2021-06-08: Extended the demo code to generate an entire sessions's
% behaviour data.
function ml_sim_behaviour_datamatrix(arena_width_cm, arena_height_cm, numTrials)
    %numTrials = 12;
    sessionStartTime_s = 0;
    timeBetweenTrials_s = 120;

    %arena_width_cm = 20;
    %arena_height_cm = 30;

    boundsx_cm = [0, arena_width_cm];
    boundsy_cm = [0, arena_height_cm];
    timePerTrial_s = 180; % Time per trial (can make random if desired)

    samplingRate_hz = 20; % Of a simulated behaviour camera.

    timeCurrent_s = sessionStartTime_s;
    dataMatrix = [];
    for iTrial = 1:numTrials
        % The t_s begins at 0
        [pos_t_s, pos_x_cm, pos_y_cm] = ml_sim_random_walk_rectangle(boundsx_cm, boundsy_cm, timePerTrial_s, samplingRate_hz);
        trialTimestamps_s = pos_t_s + timeCurrent_s;
        fprintf('%0.2f to %0.2f\n', trialTimestamps_s(1), trialTimestamps_s(end));

        trialTimestamps_s = reshape(trialTimestamps_s, numel(trialTimestamps_s), 1);
        pos_t_s = reshape(pos_t_s, numel(pos_t_s), 1);
        pos_x_cm = reshape(pos_x_cm, numel(pos_x_cm), 1);
        pos_y_cm = reshape(pos_y_cm, numel(pos_y_cm), 1);
        tids = iTrial * ones(numel(pos_t_s), 1);

        dm = [tids, trialTimestamps_s*1000.0, pos_x_cm, pos_y_cm];

        if isempty(dataMatrix)
            dataMatrix = dm;
        else
            dataMatrix = [dataMatrix; dm];
        end

        timeCurrent_s = timeCurrent_s + pos_t_s(end) + timeBetweenTrials_s;
    end

%     % Plot the path (no animation)
%     hFig = figure('position', get(0, 'screensize'));
%     for iTrial = 1:numTrials
%         trialInds = find(dataMatrix(:,1) == iTrial);
%         if isempty(trialInds)
%             continue;
%         end
% 
%         pos_x_cm = dataMatrix(trialInds, 3);
%         pos_y_cm = dataMatrix(trialInds, 4);
% 
%         subplot(2,6,iTrial);
%         plot(pos_x_cm, pos_y_cm, 'k-')
%         axis([boundsx_cm(1), boundsx_cm(2), boundsy_cm(1) boundsy_cm(2)])
%         axis equal
%         set(gca, 'ydir', 'reverse')
%     end % iTrial
end % function


