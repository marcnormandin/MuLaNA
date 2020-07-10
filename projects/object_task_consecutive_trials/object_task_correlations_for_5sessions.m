function object_task_correlations_for_5sessions(pipe)
    % This can be made dynamic and the code will still work as long as it is >= 2.
    % Isabel said there are 5, so I'm leaving it at 5 for now.
    numSessions = 5; 
    
    if pipe.Experiment.getNumSessions() ~= numSessions
        error('The object task consecutive trials experiment requires 5 sessions of data.');
    end
    
    s = MLTetrodeSession.empty;
    for iSession = 1:numSessions
        s(iSession) = pipe.Experiment.getSession(iSession);
        if s(iSession).getNumTrialsToUse() ~= 1
            error('Session (%d, %s) has (%d) trials, but must have only one.', ...
                iSession, s(iSession).getName());
        end
    end

    % Find the tfiles that are present for all sessions
    tFilesToUse = s(1).getTFilesFilenamePrefixes();
    for iSession = 2:numSessions
        tFilesToUse = intersect(tFilesToUse, s(iSession).getTFilesFilenamePrefixes());
    end
    numTFilesToUse = length(tFilesToUse);

    % We require at least 1 common tfile to proceeed
    if numTFilesToUse < 1
        warning('There are no tfiles in common with all the sessions. Nothing to process.');
        return
    end
    
    fprintf('Found %d tfiles present in both hab and test sessions: ', length(tFilesToUse));    
    for iT = 1:numTFilesToUse
        fprintf('%s ', tFilesToUse{iT});
    end
    fprintf('\n');

    % FixMe! This should check if it should use the shrunk placemaps
    placemapSubFolder = pipe.Config.placemaps.outputFolder;
    placemapFilenameSuffix = pipe.Config.placemaps.filenameSuffix;
    
    
    % Make a result structure for each common tfile
    results = [];
    for iT = 1:numTFilesToUse
        tFilePrefix = tFilesToUse{iT};
        fprintf('Processing %s\n', tFilePrefix);
        
        placemaps = cell(numSessions,1);
   
        for iSession = 1:numSessions
            session = s(iSession);
            placemapDataFolder = fullfile(session.getAnalysisDirectory(), placemapSubFolder);
            if session.getNumTrialsToUse() ~= 1
                error('Session should have only 1 trial to process!');
            end
            trial = session.getTrialToUse(1); % we already checked that there is only 1
            tmp = load( fullfile(placemapDataFolder, sprintf('%s_%d_%s', tFilePrefix, trial.getTrialId(), placemapFilenameSuffix)) );
            placemaps{iSession} = tmp.mltetrodeplacemap;
        end
        
        % Now perform the pixel-to-pixel correlations
        numComparisons = numSessions - 1;
        r = [];
        for iP = 1:numComparisons
           r(iP) = ml_core_pixel_pixel_cross_correlation_compute( placemaps{iP}.meanFiringRateMapSmoothed, placemaps{iP+1}.meanFiringRateMapSmoothed ); 
        end
        
        results(iT).tFilePrefix = tFilePrefix;
        results(iT).r = r;

        for iP = 1:length(placemaps)
           results(iT).meanFiringRate(iP) = placemaps{iP}.meanFiringRateSmoothed;
           results(iT).peakFiringRate(iP) = placemaps{iP}.peakFiringRateSmoothed;
           results(iT).informationRate(iP) = placemaps{iP}.informationRateSmoothed;
           results(iT).informationPerSpike(iP) = placemaps{iP}.informationPerSpikeSmoothed;
           results(iT).totalDwellTime(iP) = placemaps{iP}.totalDwellTime; % not smoothed, otherwise it doesnt make sense
           results(iT).totalSpikesBeforeCriteria(iP) = placemaps{iP}.totalSpikesBeforeCriteria;
           results(iT).totalSpikesAfterCriteria(iP) = placemaps{iP}.totalSpikesAfterCriteria;
        end
    end
    
    outputFilename = fullfile(pipe.Experiment.getAnalysisParentDirectory(), sprintf('%s_otcs.xlsx', pipe.Experiment.getAnimalName()));
    delete(outputFilename)
    % Write the results to an excel file
    sheets = {'meanFiringRate', 'peakFiringRate', 'informationRate', 'informationPerSpike', 'totalDwellTime', 'totalSpikesBeforeCriteria', 'totalSpikesAfterCriteria'};
    for iSheet = 1:length(sheets)
        sheet = sheets{iSheet};
        S = cell(numTFilesToUse+1, numSessions+1);
        %S(1,:) = {'','hab','t1','t2','t3','test'};
        S{1,1} = ' ';
        for iSession = 1:numSessions
            S{1,iSession+1} = s(iSession).getName();
        end
        
        for iT = 1:numTFilesToUse
            tFilePrefix = tFilesToUse{iT};
            S{iT+1,1} = tFilePrefix;
            for iP = 1:numSessions
                d = results(iT).(sheet);
                S{iT+1,iP+1} = d(iP);
            end
        end
        Tnew = array2table(S);

        writetable(Tnew, outputFilename, 'Sheet', sprintf('%s', sheet), 'WriteVariableNames', false);
    end
    
    
    sheets = {'pixel-pixel-correlation'};
    for iSheet = 1:length(sheets)
        sheet = sheets{iSheet};
        S = cell(numTFilesToUse+1, numComparisons+1);
        %S(1,:) = {'','hab-t1','t1-t2','t2-t3','t3-test'};
        S{1,1} = '';
        for iSession = 1:numComparisons
            S{1,iSession+1} = sprintf('%s corr %s', s(iSession).getName(), s(iSession+1).getName());
        end
        
        for iT = 1:numTFilesToUse
            tFilePrefix = tFilesToUse{iT};
            S{iT+1,1} = tFilePrefix;
            for iP = 1:numComparisons
                d = results(iT).r;
                S{iT+1,iP+1} = d(iP);
            end
        end
        Tnew = array2table(S);

        writetable(Tnew, outputFilename, 'Sheet', sprintf('%s', sheet), 'WriteVariableNames', false);
    end
end % function
