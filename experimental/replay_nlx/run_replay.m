close all
clear all
clc
slice_separation_threshold_ms = 10*1000;

%recordingFolder = 'T:\Shamu_two_contexts_CA1\tetrodes\recordings\feature_rich\AK42_CA1\d9';
%recordingFolder = 'T:\Shamu_two_contexts_CA1\tetrodes\recordings\feature_rich\CMG159_CA1\s8';
%recordingFolder = 'R:\temp_AK74_CA1_continuous\d1';
recordingFolder = 'T:\Shamu_two_contexts_CA1\tetrodes\recordings\feature_poor\MG1_CA1\s7';

tmp = split(recordingFolder, filesep);
mouseName = tmp{end-1};
sessionName = tmp{end};

analysisFolder = fullfile('C:\Users\fym313\Documents\MATLAB\MuLaNA\experimental\replay_nlx', mouseName, sessionName);

hFig = figure;


%
[cscFiles, numCscFiles] = ml_nlx_get_csc_filenames( recordingFolder );
channelNums = zeros(length(cscFiles), 1);
for i = 1:length(channelNums)
   [filepath, filename, ext] = fileparts( cscFiles(i).full_filename );
   tmp = filename;
   tmp = strrep(tmp, 'CSC', '');
   channelNums(i) = str2double(tmp);
end


    
% Specify a channel number
for iChannel = 1:length(channelNums)
    channelNumber = channelNums(iChannel);
    fprintf('Processing channel no. %d\n', channelNumber);
    %continue;
    

    % For some reason, Celia's channels come out that don't match what is in
    % the files.
    %channelNums = [cscFiles.channel_num];

    % Obtain channel names from the file names

    ind = find(channelNums == channelNumber);
    if isempty(ind)
        error('Unable to find file for channel number %d.\n', channelNumber);
    end
    cscFilename = cscFiles(ind).full_filename;
    [ts_mus, csc, channel, fs] = ml_nlx_csc_load_file( cscFilename );
    
    if fs == 0
        warning('The sampling frequency for %s was 0 Hz.\n', cscFilename);
        continue;
    end

    ts_ms = ts_mus / 10^3;

    % Split into slices
    slices = ml_util_timeseries_split_into_slices( ts_ms, csc, slice_separation_threshold_ms );

    % plot
    numTrials = length(slices);
    for trialNumber = 1:numTrials
        slice = slices{trialNumber};
        cscSlice = slice.x;
        tsmsSlice = slice.timeStamps_ms;
        % 
        % figure
        % plot(tsmsSlice, cscSlice)
        % xlabel('Time, t [ms]')
        % ylabel('CSC')
        % title(sprintf('Channel %d, Trial %d', channelNumber, trialNumber))
        % grid on


        % Filter Design
        filterOrder = 4;
        filterLow = 140;
        filterHigh = 250;
        samplingFrequency = fs;

        d = fdesign.bandpass('N,F3dB1,F3dB2', filterOrder, filterLow, filterHigh, samplingFrequency);
        Hd = design(d,'butter');
        b = Hd.sosMatrix; a = Hd.scaleValues;

        % check for NaNs in the data; if there are, issue a warning and replace by zeros
        temp = cscSlice;

        badIndices = find(isnan(temp));
        if ~isempty(badIndices)
            temp(badIndices) = 0;
        end

        % filter
        temp = filtfilt(b,a,temp);
        temp(badIndices) = nan;
        cscSliceFiltered = temp;

        % Plot the filtered data
        % figure
        % plot(tsmsSlice, cscSliceFiltered)
        % xlabel('Time, t [ms]')
        % ylabel('CSC Filtered')
        % title(sprintf('Channel %d, Trial %d', channelNumber, trialNumber))
        % grid on

        % Candidate sharp waves
        kernelSize_ms = 60;
        kernelSigma_ms = 20;

        kernelSize_samples = kernelSize_ms/1000.0 * samplingFrequency;
        tmp1 = rem(kernelSize_samples,1);
        tmp2 = floor(kernelSize_samples);
        tmp3 = ceil(kernelSize_samples);
        % Make the smoothing kernel
        % Make sure it is odd sized
        if mod(tmp2,2) == 0
            kernelSize_samples = tmp3;
        else
            kernelSize_samples = tmp2;
        end
        % It could be the case that tmp2 == tmp3 and both are even
        if mod(kernelSize_samples,2) == 0
            kernelSize_samples = kernelSize_samples + 1;
        end

        kernelSigma_samples = round(kernelSigma_ms/1000.0 * samplingFrequency);

        kernel = fspecial('gaussian', kernelSize_samples, kernelSigma_samples);
        kernel = kernel((size(kernel,1)+1)/2,:);

        %
        envelope = abs(cscSliceFiltered);
        envelope = conv(envelope, kernel, 'same');

        z = zscore(envelope);
        %candidateIndices = ml_util_timeseries_find_slice_indices( find(abs(z) >= 3), 1);
        minZScore = 3;
        x = z >= minZScore;
        gids = ml_util_group_points_v2(x);
        validGids = gids;
        validGids(x == 0) = [];
        ugids = unique(validGids);

        candidateIndices = [];
        for i = 1:length(ugids)
           ugid = ugids(i);
           p = find(gids == ugid, 1, 'first');
           q = find(gids == ugid, 1, 'last');

           candidateIndices(:,i) = [p, q];
        end


        % Just for debugging
        % above = z >= 3;
        % aboveIndices = find(above == 1);
        % figure
        % plot(z, 'k-')
        % hold on
        % plot(aboveIndices, z(aboveIndices), 'ro')
        % for iEvent = 1:size(candidateIndices,2)
        %     C = candidateIndices(:,iEvent);
        %     plot(C(1):C(2), z(C(1):C(2)), 'b-');
        % end

        %
        % The events should have a minimum length of 20 ms
        minDuration_ms = 20;
        if ~isempty(candidateIndices)
            candidateTimes_ms = candidateIndices / samplingFrequency * 1000;
            candidateIndices(:, candidateTimes_ms(2,:) - candidateTimes_ms(1,:) < minDuration_ms) = [];
            candidateTimes_ms = candidateIndices / samplingFrequency * 1000;
        else
            candidateTimes_ms = [];
        end

        for iEvent = 1:size(candidateIndices,2)
            C = candidateIndices(:,iEvent);
            p = C(1) - 5000;
            if p < 0
                p = 1;
            end
            q = C(2) + 5000;
            if q > length(cscSlice)
                q = length(cscSlice);
            end


            clf(hFig, 'reset');
            sgtitle(sprintf('%s %s\nChannel no. %d, Trial no. %d\nSWR no. %d', strrep(mouseName, '_', ' '), sessionName, channelNumber, trialNumber, iEvent));

            ax(1) = subplot(4,1,1);
            plot(tsmsSlice(p:q), cscSlice(p:q), 'k-')
            hold on
            plot(tsmsSlice(C(1):C(2)), cscSlice(C(1):C(2)), 'r-')
            xticks([]);
            ylabel('Raw')

            ax(2) = subplot(4,1,2);
            plot(tsmsSlice(p:q), cscSliceFiltered(p:q), 'k-')
            hold on
            plot(tsmsSlice(C(1):C(2)), cscSliceFiltered(C(1):C(2)), 'r-')
            xticks([]);
            ylabel('Filtered')

            ax(3) = subplot(4,1,3);
            plot(tsmsSlice(p:q), envelope(p:q), 'k-')
            hold on
            plot(tsmsSlice(C(1):C(2)), envelope(C(1):C(2)), 'r-')
            xticks([]);
            ylabel('Smoothed')

            ax(4) = subplot(4,1,4);
            plot(tsmsSlice(p:q), z(p:q), 'k-')
            hold on
            plot(tsmsSlice(C(1):C(2)), z(C(1):C(2)), 'r-')
            %xticks([]);
            ylabel('Z-score')

            linkaxes(ax, 'x')
            
            outputFolder = fullfile(analysisFolder, num2str(channelNumber), num2str(trialNumber));
            if ~exist(outputFolder, 'dir')
                mkdir(outputFolder);
            end
            saveas(hFig, fullfile(outputFolder, sprintf('SWR_%d.png', iEvent)));

        end
    end % iTrial
end % iChannel

