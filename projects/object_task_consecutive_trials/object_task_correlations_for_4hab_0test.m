function object_task_correlations_for_4hab_0test(pipe)
    % Get the t-files that are present for both day 1 and day 2
    if pipe.Experiment.getNumSessions() == 1
        session = pipe.Experiment.getSession(1);
        if ~strcmpi(session.getName(), 'hab')
            error('This object task consecutive trials experiment requires exactly 1 session (named hab) containing 4 trials.');
        end
    else
        error('This object task consecutive trials experiment requires exactly 1 session (named hab) containing 4 trials.');
    end
    
    % Find the tfiles that are present for the session
    s1 = pipe.Experiment.getSession(1);
    
    s1tfiles_filename_prefixes = s1.getTFilesFilenamePrefixes();
    tFilesToUse = s1tfiles_filename_prefixes;
    fprintf('Found %d tfiles present in hab session.\n', length(tFilesToUse));
    
    % Find the hab and test sessions
    if strcmpi(s1.getName(), 'hab')
        shab = s1;
    else
        error('The first and only session should be named hab.');
    end
    
    % Hab session should have 4 trials (hab, t1, t2, t3)
    if shab.getNumTrialsToUse() ~= 4
        error('The hab session should have 4 trials, but actually has %d\n', shab.getNumTrialsToUse());
    end
    
    placemapSubFolder = pipe.Config.placemaps.outputFolder;
    placemapFilenameSuffix = pipe.Config.placemaps.filenameSuffix;
    
    
    % Make a result structure for each common tfiles
    results = [];
    for iT = 1:length(tFilesToUse)
        tFilePrefix = tFilesToUse{iT};
        fprintf('Processing %s\n', tFilePrefix);
        
        placemaps = cell(4,1);
   
        % day 1 (hab, t1, t2, t3)
        placemapDataFolder = fullfile(shab.getAnalysisDirectory(), placemapSubFolder);
        % We've already checked that shab has 4 trials to process
        for iTrial = 1:shab.getNumTrialsToUse()
            trial = shab.getTrialToUse(iTrial);
            tmp = load( fullfile(placemapDataFolder, sprintf('%s_%d_%s', tFilePrefix, trial.getTrialId(), placemapFilenameSuffix)) );
            placemaps{iTrial} = tmp.mltetrodeplacemap;
        end
        
        % Now perform the pixel-to-pixel correlations
        r = [];
        for iP = 1:length(placemaps)-1
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
        S = cell(length(tFilesToUse)+1, length(placemaps)+1);
        S(1,:) = {'','hab','t1','t2','t3'};
        for iT = 1:length(tFilesToUse)
            tFilePrefix = tFilesToUse{iT};
            S{iT+1,1} = tFilePrefix;
            for iP = 1:length(placemaps)
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
        S = cell(length(tFilesToUse)+1, length(placemaps));
        S(1,:) = {'','hab-t1','t1-t2','t2-t3'};
        for iT = 1:length(tFilesToUse)
            tFilePrefix = tFilesToUse{iT};
            S{iT+1,1} = tFilePrefix;
            for iP = 1:3
                d = results(iT).r;
                S{iT+1,iP+1} = d(iP);
            end
        end
        Tnew = array2table(S);

        writetable(Tnew, outputFilename, 'Sheet', sprintf('%s', sheet), 'WriteVariableNames', false);
    end
end % function