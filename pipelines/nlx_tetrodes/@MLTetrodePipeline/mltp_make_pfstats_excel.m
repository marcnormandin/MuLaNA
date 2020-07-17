function mltp_make_pfstats_excel(obj, session)
    pfStatsFilename = fullfile(session.getAnalysisDirectory(), 'pfStats.xlsx');
    pfStatsMatFilename = fullfile(session.getAnalysisDirectory(), 'pfStats.mat');

    if isfile(pfStatsFilename)
        delete(pfStatsFilename)
    end
    
    if isfile(pfStatsMatFilename)
        delete(pfStatsMatFilename)
    end

    tFilesToUse = session.getTFilesFilenamePrefixes();
    
    numTFiles = length(tFilesToUse);
    
    if numTFiles == 0
        fprintf('No t-files found. Can not run stats.\n');
        return
    end
    
    fprintf('Found %d tfiles present in %s.\n', length(tFilesToUse), session.getName());
    
    placemapSubFolder = obj.Config.placemaps.outputFolder;
    placemapFilenameSuffix = obj.Config.placemaps.filenameSuffix;
    
    % Make a result structure for each common tfiles
    pfStats = [];
    for iTFile = 1:numTFiles
        tFilePrefix = tFilesToUse{iTFile};
        fprintf('Processing %s\n', tFilePrefix);
        
        placemaps = {};
   
        pfStats(iTFile).tFilePrefix = tFilePrefix;

        % We only want stats for the trials that we actually want to use
        placemapDataFolder = fullfile(session.getAnalysisDirectory(), placemapSubFolder);
        for iTrial = 1:session.getNumTrialsToUse()
            trial = session.getTrialToUse(iTrial);
            trialId = trial.getTrialId();
            tmp = load( fullfile(placemapDataFolder, sprintf('%s_%d_%s', tFilePrefix, trialId, placemapFilenameSuffix)) );
            placemaps{iTrial} = tmp.mltetrodeplacemap;

           pfStats(iTFile).meanFiringRate(iTrial) = placemaps{iTrial}.meanFiringRate;
           pfStats(iTFile).peakFiringRate(iTrial) = placemaps{iTrial}.peakFiringRate;
           pfStats(iTFile).informationRate(iTrial) = placemaps{iTrial}.informationRate;
           pfStats(iTFile).informationPerSpike(iTrial) = placemaps{iTrial}.informationPerSpike;
           
           pfStats(iTFile).meanFiringRateSmoothed(iTrial) = placemaps{iTrial}.meanFiringRateSmoothed;
           pfStats(iTFile).peakFiringRateSmoothed(iTrial) = placemaps{iTrial}.peakFiringRateSmoothed;
           pfStats(iTFile).informationRateSmoothed(iTrial) = placemaps{iTrial}.informationRateSmoothed;
           pfStats(iTFile).informationPerSpikeSmoothed(iTrial) = placemaps{iTrial}.informationPerSpikeSmoothed;
           
           
           pfStats(iTFile).totalDwellTime(iTrial) = placemaps{iTrial}.totalDwellTime; % not smoothed, otherwise it doesnt make sense
           pfStats(iTFile).totalSpikesBeforeCriteria(iTrial) = placemaps{iTrial}.totalSpikesBeforeCriteria;
           pfStats(iTFile).totalSpikesAfterCriteria(iTrial) = placemaps{iTrial}.totalSpikesAfterCriteria;
           pfStats(iTFile).context_id(iTrial) = tmp.trial_context_id;
           pfStats(iTFile).context_use(iTrial) = tmp.trial_use;
        end
    end
    
    % Write the pfStats to an excel file
    sheets = {...
        'meanFiringRate', 'peakFiringRate', 'informationRate', 'informationPerSpike', ...
        'meanFiringRateSmoothed', 'peakFiringRateSmoothed', 'informationRateSmoothed', 'informationPerSpikeSmoothed', ...
        'totalDwellTime', 'totalSpikesBeforeCriteria', 'totalSpikesAfterCriteria'};
    for iSheet = 1:length(sheets)
        sheet = sheets{iSheet};
        S = cell(length(tFilesToUse)+1, length(placemaps)+1);
         for iTFile = 1:numTFiles
            tFilePrefix = tFilesToUse{iTFile};
            S{1,iTFile+1} = tFilePrefix;
            for iTrial = 1:session.getNumTrialsToUse()
                trial = session.getTrialToUse(iTrial);
                S{iTrial+1,1} = trial.getSequenceId(); % name the trial
                d = pfStats(iTFile).(sheet);
                S{iTrial+1,iTFile+1} = d(iTrial);
            end
         end
        
        Tnew = array2table(S);

        writetable(Tnew, pfStatsFilename, 'Sheet', sprintf('%s', sheet), 'WriteVariableNames', false);
    end
    
    numTrials = session.getNumTrialsToUse();
    save(pfStatsMatFilename, 'pfStats', 'session', 'numTFiles', 'numTrials');
end % function