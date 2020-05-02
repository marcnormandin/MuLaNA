function mltp_make_pfstats_excel(obj, session)
    pfStatsFilename = fullfile(session.analysisFolder, 'pfStats.xlsx');
    pfStatsMatFilename = fullfile(session.analysisFolder, 'pfStats.mat');

    if isfile(pfStatsFilename)
        delete(pfStatsFilename)
    end

    % Sort them (hackish)
    % Remove the TT
    tmp2 = [];
    for i = 1:length(session.tfiles_filename_prefixes)
        tmp1 = session.tfiles_filename_prefixes{i};
        s = tmp1(3:end); % strip the TT
        s = split(s,'_');
        % Now convert to a number
        num = str2double(s{1}) * 10 + str2double(s{2});
        tmp2(end+1) = num;
    end
    % now sort them numerically
    [sortedValue, prevIndex] = sort(tmp2);
    tFilesToUse = {};
    for i = 1:length(tmp2)
        tFilesToUse{i} = session.tfiles_filename_prefixes{prevIndex(i)};
    end
    
    numTFiles = length(tFilesToUse);
    
    sr = session.sessionRecord;
    ti = sr.getTrialsToProcess();
    
    numTrials = sr.getNumTrialsToProcess();
    
    fprintf('Found %d tfiles present in %s.\n', length(tFilesToUse), sr.getName());
    
    placemapSubFolder = obj.config.placemaps.outputFolder;
    placemapFilenameSuffix = obj.config.placemaps.filenameSuffix;
    
    % Make a result structure for each common tfiles
    results = [];
    for iTFile = 1:numTFiles
        tFilePrefix = tFilesToUse{iTFile};
        fprintf('Processing %s\n', tFilePrefix);
        
        placemaps = {};
   
        placemapDataFolder = fullfile(session.analysisFolder, placemapSubFolder);
        for iTrial = 1:numTrials
            trialId = ti(iTrial).id;
            tmp = load( fullfile(placemapDataFolder, sprintf('%s_%d_%s', tFilePrefix, trialId, placemapFilenameSuffix)) );
            placemaps{iTrial} = tmp.mltetrodeplacemap;
        end
        
        results(iTFile).tFilePrefix = tFilePrefix;

        for iTrial = 1:numTrials
           results(iTFile).meanFiringRate(iTrial) = placemaps{iTrial}.meanFiringRateSmoothed;
           results(iTFile).peakFiringRate(iTrial) = placemaps{iTrial}.peakFiringRateSmoothed;
           results(iTFile).informationRate(iTrial) = placemaps{iTrial}.informationRateSmoothed;
           results(iTFile).informationPerSpike(iTrial) = placemaps{iTrial}.informationPerSpikeSmoothed;
           results(iTFile).totalDwellTime(iTrial) = placemaps{iTrial}.totalDwellTime; % not smoothed, otherwise it doesnt make sense
           results(iTFile).totalSpikesBeforeCriteria(iTrial) = placemaps{iTrial}.totalSpikesBeforeCriteria;
           results(iTFile).totalSpikesAfterCriteria(iTrial) = placemaps{iTrial}.totalSpikesAfterCriteria;
        end
    end
    
    % Write the results to an excel file
    sheets = {'meanFiringRate', 'peakFiringRate', 'informationRate', 'informationPerSpike', 'totalDwellTime', 'totalSpikesBeforeCriteria', 'totalSpikesAfterCriteria'};
    for iSheet = 1:length(sheets)
        sheet = sheets{iSheet};
        S = cell(length(tFilesToUse)+1, length(placemaps)+1);
         for iTFile = 1:numTFiles
            tFilePrefix = tFilesToUse{iTFile};
            S{1,iTFile+1} = tFilePrefix;
            for iTrial = 1:numTrials
                S{iTrial+1,1} = ti(iTrial).sequenceNum; % name the trial
                d = results(iTFile).(sheet);
                S{iTrial+1,iTFile+1} = d(iTrial);
            end
         end
        
        Tnew = array2table(S);

        writetable(Tnew, pfStatsFilename, 'Sheet', sprintf('%s', sheet), 'WriteVariableNames', false);
    end
    
    save(pfStatsMatFilename, 'results', 'session');
end % function