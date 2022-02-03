function compute_popvectors_dotproduct_cumulative(obj, session)
    animalName = obj.Experiment.getAnimalName();
    sessionName = session.getName();
    sessionAnalysisFolder = session.getAnalysisDirectory();
   
    mapNameToUse = obj.Config.calcium_popvectors_dotproduct_cumulative.map_name_to_use;
    
    sessionData = load(fullfile(sessionAnalysisFolder, sprintf("%s_placemaps.mat", sessionName)));

    
    applyFilterInformationContent = obj.Config.calcium_popvectors_dotproduct_cumulative.apply_filter_information_content;
    applyFilterCelllikeSpatialFootprint = obj.Config.calcium_popvectors_dotproduct_cumulative.apply_filter_celllike_spatial_footprint;
    applyFilter = applyFilterInformationContent | applyFilterCelllikeSpatialFootprint;
    

    sdataMaps = sessionData.(mapNameToUse);
    sdataCellIds = sessionData.cellIds;
    sdataTrialIds = sessionData.trialIds;
    sdataContextIds = sessionData.contextIds;
    
    
    % Apply filtering if desired
    if applyFilter
        inclusionFilename = fullfile(sessionAnalysisFolder, sprintf('%s_placemaps_inclusion.mat', sessionName));
        if ~isfile(inclusionFilename)
            warning('Filtering is on, but can not be applied because the required file (%s) does not exist. No filtering will be applied.\n', inclusionFilename);
        else
            tmp = load(inclusionFilename);
        
            inclusionData = tmp.inclusionData;
            
            % Should check that everything matches
            tmp1 = [inclusionData.cellIds, inclusionData.contextIds, inclusionData.trialIds];
            tmp2 = [sdataCellIds, sdataContextIds, sdataTrialIds];
            
            if ~all(tmp1-tmp2 == 0, 'all')
                error('Corrupt or out of sync data. One of cell ids, trial ids, or context ids do not match.\n');
            end
            
            isValid = true(length(inclusionData.cellIds),1);
            if applyFilterInformationContent
                isValid = isValid & inclusionData.passedInformationContentFilter;
            end
            if applyFilterCelllikeSpatialFootprint
                isValid = isValid & inclusionData.passedCelllikeSpatialFootprintFilter;
            end
            
            % Filter filter
            sdataMaps(:,:, ~isValid) = [];
            sdataCellIds(~isValid) = [];
            sdataTrialIds(~isValid) = [];
            sdataContextIds(~isValid) = [];
        end
    end
    
    
    numContexts = length(unique(sdataContextIds));
    if numContexts ~= 2
        warning('Function can only be applied to a two-context session. Skipping.\n');
        return
    end
    

    % main algorithm
    results = ml_alg_popvectors_cumulative_similarity(sdataMaps, sdataCellIds, sdataTrialIds, sdataContextIds);


    %
    hFig = figure('position', get(0, 'screensize'));
    plot(results.uzC1, results.czC1, 'r-', 'linewidth', 2)
    hold on
    plot(results.uzC2, results.czC2, 'g-', 'linewidth', 2)
    plot(results.uzAcross, results.czAcross, 'b', 'linewidth', 2)
    plot(results.uzWithin, results.czWithin, 'k-', 'linewidth', 2)

    legend({'C1', 'C2', 'Across', 'Within'})
    grid on
    xlabel('Population Vector Dot Product', 'fontweight', 'bold')
    ylabel('Cumulative Distribution', 'fontweight', 'bold')
    title(sprintf('%s %s', animalName, sessionName), 'interpreter', 'none')
    
    outputFigFilename = fullfile(sessionAnalysisFolder, sprintf('%s_compute_popvectors_dotproduct_cumulative_%s.fig', sessionName, mapNameToUse));
    savefig(hFig, outputFigFilename);
    
    outputSvgFilename = fullfile(sessionAnalysisFolder, sprintf('%s_compute_popvectors_dotproduct_cumulative_%s.svg', sessionName, mapNameToUse));
    saveas(hFig, outputSvgFilename);
    
    close(hFig);
    
    %%
    save(fullfile(sessionAnalysisFolder, sprintf('%s_compute_popvectors_dotproduct_cumulative_%s.mat', sessionName, mapNameToUse)), ...
        'results', ...
        'animalName', 'sessionName', 'mapNameToUse');

end % function



