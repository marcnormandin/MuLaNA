function object_task_correlations(pipe)
% Get the t-files that are present for both day 1 and day 2
    if pipe.experiment.numSessions ~= 2
        error('The object task consecutive trials experiments requires only two sessions of data.');
    end
    
    % Find the tfiles that are present for all sessions
    s1 = pipe.experiment.session{1};
    s2 = pipe.experiment.session{2};
    tFilesToUse = s1.tfiles_filename_prefixes(ismember(s1.tfiles_filename_prefixes, s2.tfiles_filename_prefixes));
    fprintf('Found %d tfiles present in both hab and test sessions.\n', length(tFilesToUse));
    
    % Find the hab and test sessions
    if strcmpi(s1.name, 'hab') && strcmpi(s2.name, 'test')
        shab = s1;
        stest = s2;
    elseif strcmpi(s1.name, 'test') && strcmpi(s2.name, 'hab')
        shab = s2;
        stest = s1;
    else
        error('One session should be named hab and the other test');
    end
    
    % Hab session should have 4 trials (hab, t1, t2, t3)
    if shab.num_trials_to_use ~= 4
        error('The hab session should have 4 trials, but actually has %d\n', shab.num_trials_to_use);
    end
    
    % Test session should have only 1 trial (test)
    if stest.num_trials_to_use ~= 1
        error('The test session should have 1 trial, but actually has %d.\n', stest.num_trials_to_use);
    end
    
    % Get the correct placemap data
    if strcmpi(pipe.getArena().shape, 'rectangle')
        fprintf('Computing placefield stats excel file using rectangle data.\n');
        placemapSubFolder = 'placemaps_rectangle';
        placemapFilenameSuffix = 'mltetrodeplacemaprect.mat';
    elseif strcmpi(pipe.getArena().shape, 'square')
        fprintf('Computing placefield stats excel file using square data.\n');
        placemapSubFolder = 'placemaps_square';
        placemapFilenameSuffix = 'mltetrodeplacemapsquare.mat';
    else
        error('Placefield stats excel file creation is only valid for rectangle or square, not %s.', obj.getArena().shape);
    end
    
    
    % Make a result structure for each common tfiles
    results = [];
    for iT = 1:length(tFilesToUse)
        tFilePrefix = tFilesToUse{iT};
        fprintf('Processing %s\n', tFilePrefix);
        
        placemaps = {};
   
        % day 1 (hab, t1, t2, t3)
        placemapDataFolder = fullfile(shab.analysisFolder, placemapSubFolder);
        for iTrial = 1:shab.num_trials_to_use
            tmp = load( fullfile(placemapDataFolder, sprintf('%s_%d_%s', tFilePrefix, iTrial, placemapFilenameSuffix)) );
            placemaps{iTrial} = tmp.mltetrodeplacemap;
        end
        
        % day 2 (test)
        placemapDataFolder = fullfile(stest.analysisFolder, placemapSubFolder);
        for iTrial = 1:stest.num_trials_to_use
            tmp = load( fullfile(placemapDataFolder, sprintf('%s_%d_%s', tFilePrefix, iTrial, placemapFilenameSuffix)) );
            placemaps{iTrial+shab.num_trials_to_use} = tmp.mltetrodeplacemap;
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
    
    outputFilename = fullfile(pipe.analysisParentFolder, sprintf('%s_otcs.xlsx', pipe.experiment.subjectName));
    delete(outputFilename)
    % Write the results to an excel file
    sheets = {'meanFiringRate', 'peakFiringRate', 'informationRate', 'informationPerSpike', 'totalDwellTime', 'totalSpikesBeforeCriteria', 'totalSpikesAfterCriteria'};
    for iSheet = 1:length(sheets)
        sheet = sheets{iSheet};
        S = cell(length(tFilesToUse)+1, length(placemaps)+1);
        S(1,:) = {'','hab','t1','t2','t3','test'};
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
        S = cell(length(tFilesToUse)+1, 5);
        S(1,:) = {'','hab-t1','t1-t2','t2-t3','t3-test'};
        for iT = 1:length(tFilesToUse)
            tFilePrefix = tFilesToUse{iT};
            S{iT+1,1} = tFilePrefix;
            for iP = 1:4
                d = results(iT).r;
                S{iT+1,iP+1} = d(iP);
            end
        end
        Tnew = array2table(S);

        writetable(Tnew, outputFilename, 'Sheet', sprintf('%s', sheet), 'WriteVariableNames', false);
    end
end % function