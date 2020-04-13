function mltp_make_pfstats_excel(obj, session)
    pfStatsFilename = fullfile(session.analysisFolder, 'pfStats.xlsx');
    pfStatsMatFilename = fullfile(session.analysisFolder, 'pfStats.mat');

    if isfile(pfStatsFilename)
        delete(pfStatsFilename)
    end

    % Maybe only use the trials that are desired, instead of all of them.
    numTrials = session.num_trials_recorded;
    
    % Get the correct placemap data
    if strcmpi(obj.getArena().shape, 'rectangle')
        fprintf('Computing placefield stats excel file using rectangle data.\n');
        placemapSubFolder = 'placemaps_rectangle';
        placemapFilenameSuffix = 'mltetrodeplacemaprect.mat';
    elseif strcmpi(obj.getArena().shape, 'square')
        fprintf('Computing placefield stats excel file using square data.\n');
        placemapSubFolder = 'placemaps_square';
        placemapFilenameSuffix = 'mltetrodeplacemapsquare.mat';
    else
        error('Placefield stats excel file creation is only valid for rectangle or square, not %s.', obj.getArena().shape);
    end
    
    placemapDataFolder = fullfile(session.analysisFolder, placemapSubFolder);
    fileList = dir(fullfile(placemapDataFolder, sprintf('*_%s', placemapFilenameSuffix)));

    sessionName = session.name;

    fns = {fileList.name};
    ttname = {};
    for i = 1:length(fns)
        s = split(fns{i}, '_');
        ttname = [ttname, sprintf('%s_%s', s{1}, s{2})];
    end
    ttname = sort(unique(ttname));

    pfStats = []; %struct(length(ttname), numTrials);
    for iTT = 1:length(ttname)
        for iTrial = 1:numTrials
            dataFilename = sprintf('%s_%d_%s', ttname{iTT}, iTrial, placemapFilenameSuffix);
            fprintf('Loading %s\n', dataFilename);
            data = load(fullfile(placemapDataFolder, dataFilename));
            x = data.mltetrodeplacemap;

            pfStats(iTT, iTrial).ttname = ttname{iTT};
            pfStats(iTT, iTrial).totalSpikesBeforeCriteria = x.totalSpikesBeforeCriteria;
            pfStats(iTT, iTrial).totalSpikesAfterCriteria = x.totalSpikesAfterCriteria;
            pfStats(iTT, iTrial).meanFiringRate = x.meanFiringRate;
            pfStats(iTT, iTrial).peakFiringRate = x.peakFiringRate;
            pfStats(iTT, iTrial).informationRate = x.informationRate;
            pfStats(iTT, iTrial).informationPerSpike = x.informationPerSpike;
            pfStats(iTT, iTrial).context_id = data.trial_context_id;
            pfStats(iTT, iTrial).context_use = data.trial_use;
        end
    end

    statsVariables = {'totalSpikesBeforeCriteria', 'totalSpikesAfterCriteria', 'meanFiringRate', 'peakFiringRate', 'informationRate', 'informationPerSpike'};
    for iStats = 1:length(statsVariables)
        S = zeros(size(pfStats,2)+1, size(pfStats,1)+1);
        for i = 2:size(pfStats,1)+1
            S(1,i) = i-1; %ttname{i-1};
        end
        for j = 2:size(pfStats,2)+1
            S(j,1) = j-1;
        end

        for iRow = 2:size(pfStats,2)+1
            for iCol = 2:size(pfStats,1)+1
                S(iRow, iCol) = pfStats(iCol-1, iRow-1).(statsVariables{iStats});
            end
        end

        Tnew = array2table(S);

        writetable(Tnew, pfStatsFilename, 'Sheet', sprintf('%s_%s', sessionName, statsVariables{iStats}), 'WriteVariableNames', false);
    end
    
    save(pfStatsMatFilename, 'pfStats', 'session');
end % function