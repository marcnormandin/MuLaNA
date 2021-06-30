function ml_sim_tetrode_data_plot(simDataFolder)
    tmp = load(fullfile(simDataFolder, 'dataMatrix.mat'));
    dataMatrix = tmp.dataMatrix;
    clear tmp

    tFiles = dir(fullfile(simDataFolder, '*.t'));
    numTFiles = length(tFiles);

    cellSpikes = cell(numTFiles,1);
    for iFile = 1:numTFiles
       f = tFiles(iFile);
       x = ml_nlx_mclust_load_spikes_64bit( fullfile(f.folder, f.name) );
       ts_mus_64 = x .* 10^6;
       ts_ms = ts_mus_64 / 1000.0;

       cellSpikes{iFile} = ts_ms;
    end

    % Plot

    trialIds = dataMatrix(:,1);
    numTrials = max(trialIds);
    behaviour_timestamps_ms = dataMatrix(:,2);
    behaviour_pos_x_cm = dataMatrix(:,3);
    behaviour_pos_y_cm = dataMatrix(:,4);

    numCells = length(cellSpikes);
    for iCell = 1:numCells
       hFig = figure('position', get(0, 'screensize'));

       cellSpikeTimestamps_ms = cellSpikes{iCell};

       for iTrial = 1:numTrials
           trialInds = find(trialIds == iTrial);
           if isempty(trialInds)
               continue;
           end

           trial_pos_x_cm = behaviour_pos_x_cm(trialInds);
           trial_pos_y_cm = behaviour_pos_y_cm(trialInds);

           % Find the spikes associated with the trial
           trial_timestamps_ms = behaviour_timestamps_ms(trialInds);
           spikeInds = intersect( find(cellSpikeTimestamps_ms >= min(trial_timestamps_ms)), find(cellSpikeTimestamps_ms <= max(trial_timestamps_ms)) );
           trialSpikeTimestamps_ms = cellSpikeTimestamps_ms(spikeInds);
           numSpikes = length(trialSpikeTimestamps_ms);

           spike_pos_x_cm = [];
           spike_pos_y_cm = [];

           % Find the position associated with each spike time
           for iSpike = 1:numSpikes
              st = trialSpikeTimestamps_ms(iSpike);
              i = find(trial_timestamps_ms >= st, 1, 'first');
              if ~isempty(i)
    %               j = i + 1;
    %               if j <= length(trial_timestamps_ms)
    %                   % Now interpolate between the two points
    %                   sx = interp1([trial_timestamps_ms(i), trial_timestamps_ms(j)], [trial_pos_x_cm(i), trial_pos_x_cm(j)], st);
    %                   sy = interp1([trial_timestamps_ms(i), trial_timestamps_ms(j)], [trial_pos_y_cm(i), trial_pos_y_cm(j)], st);
    %                   
    %                   spike_pos_x_cm(end+1) = sx;
    %                   spike_pos_y_cm(end+1) = sy;
    %               end
                    spike_pos_x_cm(end+1) = trial_pos_x_cm(i);
                    spike_pos_y_cm(end+1) = trial_pos_y_cm(i);
              end
           end

           subplot(2,6,iTrial);
           plot(trial_pos_x_cm, trial_pos_y_cm, 'k-');

           if ~isempty(spike_pos_x_cm)
               hold on
               plot(spike_pos_x_cm, spike_pos_y_cm, 'ro', 'markerfacecolor', 'r', 'markersize', 4);
           end

           set(gca, 'ydir', 'reverse');
           title(sprintf('Trial %d', iTrial));
       end
    end
end