function aligned_similarity_score_run()


[dataPoor, dataRich] = load_feature_data();

sessionStatsPoor = cell(length(dataPoor),1);
for iData = 1:length(dataPoor)
    sessionStatsPoor{iData} = compute_and_plot_corr_stats_per_session(dataPoor(iData));
end

maxDays = 0;
for iMouse = 1:length(sessionStatsPoor)
    s = sessionStatsPoor{iMouse};
    numDays = size(s,1);
    if numDays > maxDays
        maxDays = numDays;
    end
end

meansPoor = cell(maxDays,1);
for iMouse = 1:length(sessionStatsPoor)
    s = sessionStatsPoor{iMouse};
    numDays = size(s,1);
    for iDay = 1:numDays
        v = s(iDay,1);
        if ~isnan(v)
            meansPoor{iDay} = [meansPoor{iDay}, v];
        end
    end
end

meansPoorf = zeros(maxDays,2);
for iDay = 1:length(meansPoor)
    meansPoorf(iDay,1) = mean(meansPoor{iDay},'all', 'omitnan');
    meansPoorf(iDay,2) = std(meansPoor{iDay},0,'all', 'omitnan');
end

sessionStatsRich = cell(length(dataRich),1);
for iData = 1:length(dataRich)
    sessionStatsRich{iData} = compute_and_plot_corr_stats_per_session(dataRich(iData));
end

maxDays = 0;
for iMouse = 1:length(sessionStatsRich)
    s = sessionStatsRich{iMouse};
    numDays = size(s,1);
    if numDays > maxDays
        maxDays = numDays;
    end
end

meansRich = cell(maxDays,1);
for iMouse = 1:length(sessionStatsRich)
    s = sessionStatsRich{iMouse};
    numDays = size(s,1);
    for iDay = 1:numDays
        v = s(iDay,1);
        if ~isnan(v)
            meansRich{iDay} = [meansRich{iDay}, v];
        end
    end
end

meansRichf = zeros(maxDays,2);
for iDay = 1:length(meansRich)
    meansRichf(iDay,1) = mean(meansRich{iDay},'all', 'omitnan');
    meansRichf(iDay,2) = std(meansRich{iDay},0,'all', 'omitnan');
end

h = figure();
subplot(2,1,1);
ml_util_corr_errorbar_groups(meansPoorf(:,1), meansPoorf(:,2))
title(sprintf('Feature Poor (averaged across %d animals)', length(dataPoor)))
l = cell(size(meansPoorf,1),1);
for i = 1:length(l)
    l{i} = sprintf('Day %d', i);
end
legend(l);

subplot(2,1,2);
ml_util_corr_errorbar_groups(meansRichf(:,1), meansRichf(:,2))
title(sprintf('Feature Rich (averaged across %d animals)', length(dataRich)))
l = cell(size(meansRichf,1),1);
for i = 1:length(l)
    l{i} = sprintf('Day %d', i);
end
legend(l);

projectCfgFilename = fullfile(pwd, 'project_config.json');
projectConfig = mulana_json_read( projectCfgFilename );
outputFolder = projectConfig.analysisFolder;
saveas(h, fullfile(outputFolder, 'averaged_correlations.png'));
close(h)

end % function

function sessionStats = compute_and_plot_corr_stats_per_session(data)
    % Don't change these
    pipeCfgFilename = fullfile(pwd, 'pipeline_config.json');
    pipeCfg = ml_util_json_read( pipeCfgFilename );

    pipe = load_pipe_from_data(pipeCfg, data);
    numSessions = pipe.Experiment.getNumSessions();
    sessionStats = zeros(numSessions, 2); % mean, std
    sessionNames = cell(numSessions,1);
    for iSession = 1:numSessions
        [meanCorrSession, stdCorrSession] = load_session_stats(pipe, iSession);
        sessionStats(iSession,1) = meanCorrSession;
        sessionStats(iSession,2) = stdCorrSession;

        s = pipe.Experiment.getSession(iSession);
        sessionNames{iSession} = s.getName();
    end

    h = figure();
    ml_util_corr_errorbar_groups(sessionStats(:,1), sessionStats(:,2))
    legend(sessionNames)
    title(pipe.Experiment.getAnimalName(), 'interpreter', 'none');

    outputFolder = fullfile(pipe.Experiment.getAnalysisParentDirectory(), pipe.Config.best_fit_orientations.outputFolder);
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end

    saveas(h, fullfile(outputFolder, 'session_correlations.png'));
    close(h)
end % function


function [meanCorrSession, stdCorrSession] = load_session_stats(pipe, iSession)
    s = pipe.Experiment.getSession(iSession);
    inputFolder = fullfile(s.getAnalysisDirectory(), pipe.Config.best_fit_orientations.outputFolder);
    inFile = fullfile(inputFolder, 'bfo_180_percell.mat');
    d = dir(inFile);
    if isempty(d)
        fprintf('Skipping because bfo_180_percell.mat was not found.\n');
        return
    end
    tmp = load(inFile);
    perCell = tmp.perCell;
    numCells = length(perCell);
    avgCorrAll = [perCell(:).avg_corr_all];
    meanCorrSession = mean(avgCorrAll,'all', 'omitnan');
    stdCorrSession = std(avgCorrAll, 0, 'all', 'omitnan');
end % function

function [dataPoor, dataRich] = load_feature_data()
    % Load the project configuration
    projectCfgFilename = fullfile(pwd, 'project_config.json');
    projectConfig = mulana_json_read( projectCfgFilename );
    disp(projectConfig)

    % Search for mice
    [featurePoor, descFP_bad] = mulana_experiment_descriptions_search( projectConfig.dataFeaturePoorFolder );
    [featureRich, descFR_bad] = mulana_experiment_descriptions_search( projectConfig.dataFeatureRichFolder );

    % Report any problems
    for i = 1:length(descFP_bad)
        fprintf('Problems encountered reading feature poor: %s\n', descFP_bad.folder);
    end
    for i = 1:length(descFR_bad)
        fprintf('Problems encountered reading feature rich: %s\n', descFR_bad.folder);
    end

    % Add the mice data so user can be selective
    dataPoor = [];
    for iExp = 1:length(featurePoor)
        k = length(dataPoor)+1;
        edjson = featurePoor(iExp).json;
        dataPoor(k).edFolder = featurePoor(iExp).folder;
        dataPoor(k).edFilename = featurePoor(iExp).fullFilename;
        dataPoor(k).subjectName = edjson.animal;
        dataPoor(k).experiment = edjson.experiment;
        dataPoor(k).region = edjson.imaging_region;
        dataPoor(k).arena = edjson.arena;
        dataPoor(k).recordingsParentFolder = featurePoor(iExp).folder;
        dataPoor(k).analysisParentFolder = fullfile(projectConfig.analysisFeaturePoorFolder, dataPoor(k).subjectName);
        dataPoor(k).featureType = 'poor';
    end % iExp

    dataRich = [];
    for iExp = 1:length(featureRich)
        k = length(dataRich)+1;
        edjson = featureRich(iExp).json;
        dataRich(k).edFolder = featureRich(iExp).folder;
        dataRich(k).edFilename = featureRich(iExp).fullFilename;
        dataRich(k).subjectName = edjson.animal;
        dataRich(k).experiment = edjson.experiment;
        dataRich(k).region = edjson.imaging_region;
        dataRich(k).arena = edjson.arena;
        dataRich(k).recordingsParentFolder = featureRich(iExp).folder;
        dataRich(k).analysisParentFolder = fullfile(projectConfig.analysisFeatureRichFolder, dataRich(k).subjectName);
        dataRich(k).featureType = 'rich';
    end % iExp

end % function


function pipe = load_pipe_from_data(pipeCfg, data)
    subjectName = data.subjectName;
    experiment = data.experiment;
    edFilename = data.edFilename;
    edFolder = data.edFolder;
    
    recordingsParentFolder = data.edFolder;
    analysisParentFolder = data.analysisParentFolder;
    
    pipe = MLTetrodePipeline( pipeCfg, recordingsParentFolder, analysisParentFolder);
end % function
