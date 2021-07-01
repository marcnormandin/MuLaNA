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
        for iTrial = 1:session.getNumTrials()
            trial = session.getTrialByOrder(iTrial);
            trialId = trial.getTrialId();
            sliceId = trial.getSliceId();
            
            tmp = load( fullfile(placemapDataFolder, sprintf('%s_%d_%s', tFilePrefix, trialId, placemapFilenameSuffix)) );
            if tmp.trial_id ~= trialId
                error('The trial ids do not match! Logic error.');
            end
            if tmp.slice_id ~= sliceId
                error('The slice ids do not match! Logic error.');
            end
            
           placemaps{trialId} = tmp.mltetrodeplacemap;
            
           

           pfStats(iTFile).meanFiringRate(trialId) = placemaps{trialId}.meanFiringRate;
           pfStats(iTFile).peakFiringRate(trialId) = placemaps{trialId}.peakFiringRate;
           
           % p-values are only for the not-smoothed placemap
           pfStats(iTFile).informationRate(trialId) = placemaps{trialId}.informationRate;
           pfStats(iTFile).informationRate_pvalue(trialId) = placemaps{trialId}.informationRate_pvalue;
           
           % p-values are only for the not-smoothed placemap
           pfStats(iTFile).informationPerSpike(trialId) = placemaps{trialId}.informationPerSpike;
           pfStats(iTFile).informationPerSpike_pvalue(trialId) = placemaps{trialId}.informationPerSpike_pvalue;
           
           pfStats(iTFile).meanFiringRateSmoothed(trialId) = placemaps{trialId}.meanFiringRateSmoothed;
           pfStats(iTFile).peakFiringRateSmoothed(trialId) = placemaps{trialId}.peakFiringRateSmoothed;
           pfStats(iTFile).informationRateSmoothed(trialId) = placemaps{trialId}.informationRateSmoothed;
           pfStats(iTFile).informationPerSpikeSmoothed(trialId) = placemaps{trialId}.informationPerSpikeSmoothed;
           
           
           pfStats(iTFile).totalDwellTime(trialId) = placemaps{trialId}.totalDwellTime; % not smoothed, otherwise it doesnt make sense
           pfStats(iTFile).totalSpikesBeforeCriteria(trialId) = placemaps{trialId}.totalSpikesBeforeCriteria;
           pfStats(iTFile).totalSpikesAfterCriteria(trialId) = placemaps{trialId}.totalSpikesAfterCriteria;
           pfStats(iTFile).context_id(trialId) = tmp.trial_context_id;
           pfStats(iTFile).context_use(trialId) = tmp.trial_use;
           pfStats(iTFile).trial_id(trialId) = trialId;
           pfStats(iTFile).slice_id(trialId) = sliceId;
        end
    end
    
    % Write the pfStats to an excel file
    sheets = {...
        'meanFiringRate', 'peakFiringRate', 'informationRate', 'informationPerSpike', ...
        'meanFiringRateSmoothed', 'peakFiringRateSmoothed', 'informationRateSmoothed', 'informationPerSpikeSmoothed', ...
        'totalDwellTime', 'totalSpikesBeforeCriteria', 'totalSpikesAfterCriteria', 'trial_id', 'slice_id'};
    for iSheet = 1:length(sheets)
        sheet = sheets{iSheet};
        S = cell(length(tFilesToUse)+1, length(placemaps)+1);
         for iTFile = 1:numTFiles
            tFilePrefix = tFilesToUse{iTFile};
            S{1,iTFile+1} = tFilePrefix;
            
            d = pfStats(iTFile).(sheet);
            
            numTrials = length(d); % Just use any of the arrays as they are all the same length
            for k = 1:numTrials
                %trial = session.getTrialToUse(iTrial);
                %S{iTrial+1,1} = trial.getSequenceId(); % name the trial
                S{k+1,1} = k;
                
                S{k+1,iTFile+1} = d(k);
            end
         end
        
        Tnew = array2table(S);

        writetable(Tnew, pfStatsFilename, 'Sheet', sprintf('%s', sheet), 'WriteVariableNames', false);
    end
    
    %numTrials = session.getNumTrialsToUse();
    save(pfStatsMatFilename, 'pfStats', 'session', 'numTFiles');
end % function