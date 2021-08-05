 function mltp_compute_best_match_rotation_rect(obj, session)
    [bfo_dist, angleCorrelations, angleCounts] = compute_best_match_rotation_rect(obj, session);
    
    best_match_rotations.bfo_dist = bfo_dist;
    best_match_rotations.angleCorrelations = angleCorrelations;
    best_match_rotations.angleCounts = angleCounts;
    
    folder = fullfile(session.getAnalysisDirectory(), 'best_match_rotations');
    if ~exist(folder)
        mkdir(folder);
    end
    fn = fullfile(folder, 'best_match_rotations.mat');
    save(fn, 'best_match_rotations');
    
    h = figure();
    bar(1:4, bfo_dist*100)
    title(sprintf('Best Match Rotations\n%s, %s, %d cells', obj.Experiment.getAnimalName(), session.getName(), session.getNumTFiles()));
    set(gca,'XTickLabel',{['0' char(176)], ['90' char(176)], ['180' char(176)], ['270' char(176)]})
    grid on
    ylabel('Percent')
    xlabel('Rotation Angle')
    fn = fullfile(folder, 'best_match_rotation_all.png');
    saveas(h, fn);
    close(h);
end

function [bfo_dist, angleCorrelations, angleCounts] = compute_best_match_rotation_rect(obj, session)
    tfilePrefixes = session.getTFilesFilenamePrefixes();
    numTFiles = session.getNumTFiles();
    angleCounts = [];
    angleCorrelations = [];
    for iT = 1:numTFiles
        prefix = tfilePrefixes{iT};
        fileNames = dir(fullfile(session.getAnalysisDirectory(), obj.Config.placemaps.outputFolderShrunk, sprintf('%s_*_%s', prefix, obj.Config.placemaps.filenameSuffix)));
        cellPlacemaps = [];
        for iMap = 1:length(fileNames)
           cellPlacemaps{iMap} = load( fullfile(fileNames(iMap).folder, fileNames(iMap).name) ); 
        end

        trialIds = cellfun(@(x)(x.trial_id), cellPlacemaps);
        contextIds_unsorted = cellfun(@(x)(x.trial_context_id), cellPlacemaps);
        maxId = max(trialIds);
        exampleMap = cellPlacemaps{1}.mltetrodeplacemap.meanFiringRateMapSmoothed;
        ratemaps = nan(size(exampleMap,1), size(exampleMap,2), maxId);
        contextIds = nan(maxId,1);
        for i = 1:length(trialIds)
           ratemaps(:,:, trialIds(i)) = cellPlacemaps{i}.mltetrodeplacemap.meanFiringRateMapSmoothed;
           contextIds(trialIds(i)) = contextIds_unsorted(i);
        end

        uniqueContextIds = unique(contextIds);
        numContexts = length(uniqueContextIds);

        % 
        % figure()
        % for i = 1:maxId
        %     subplot(2,6,i)
        %     imagesc(ratemaps(:,:,i))
        %     title(sprintf('T%dC%d', i, contextIds(i)))
        %     axis equal off
        % end
        % figure()
        % for iContext = 1:numContexts
        %     context = uniqueContextIds(iContext);
        %     imatches = find(contextIds == context);
        %     numMatches = length(imatches);
        %     for i = 1:numMatches
        %         k = (iContext-1)*6 + i;
        %         subplot(numContexts,6,k)
        %         imagesc(ratemaps(:,:,imatches(i)))
        %         colormap jet
        %         title(sprintf('T%dC%d', imatches(i), contextIds(imatches(i))))
        %         axis equal off
        %     end
        % end

        numMaps = size(ratemaps,3);
        k = 1;
        r = [];
        for iMap1 = 1:numMaps
            m1 = ratemaps(:,:,iMap1);
            if all(m1==0, 'all') || isempty(m1)
                continue;
            end
            for iMap2 = iMap1+1:numMaps
                m2 = ratemaps(:,:,iMap2);
                if all(m2 == 0, 'all') || isempty(m2)
                    continue;
                end
                r(k,:) = compute_corr_rot(m1,m2);
                k = k + 1;
            end
        end

        maxValues = [];
        maxIndices = [];
        for i = 1:size(r,1)
           v = max(r(i,:));
           maxi = find(r(i,:) == v);
           for j = 1:length(maxi)
              maxValues(end+1) = v;
              maxIndices(end+1) = maxi(j);
           end
        end

        angleCounts(iT,:) = histcounts(maxIndices, 1:5);
        angleCorrelations(iT) = mean(maxValues, 'all');
    end % function 


    bfo_dist = sum(angleCounts,1) ./ sum(angleCounts,'all');

    %%
    % u = sort(unique(angleCorrelations));
    % s = zeros(1, length(u));
    % for i = 1:length(u)
    %     s(i) = sum(angleCorrelations <= u(i));
    % end
    % figure
    % plot(u,s,'k-','linewidth', 2)

end % function


function [r_angle] = compute_corr_rot(x,y)
    r_angle = nan(4,1);
    for i = 1:4
        p = x;
        q = rot90(y,i-1);
        % Must be linearized
        a = p(:);
        b = q(:);

        rr = corrcoef([a, b]);
        r_angle(i) = rr(1,2);
    end
end % function