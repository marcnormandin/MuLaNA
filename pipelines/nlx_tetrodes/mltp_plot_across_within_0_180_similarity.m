function mltp_plot_across_within_0_180_similarity(obj, session)
    % Load the data
    matFilename = fullfile(session.analysisFolder,  obj.config.canon_rect_placemaps_folder, 'best_fit_orientations_0_180_per_cell.mat');
    if ~isfile(matFilename)
        error('The data file (%s) does not exist. Make sure it has been computed.\n', matFilename);
    end   
    tmp = load( matFilename );
    data = tmp.best_fit_orientations_per_cell;

    numCells = length(data);


    angles = [0, 180];

    alignedMapSimilarityAcross = [];
    alignedMapSimilarityWithin = [];
    for iCell = 1:numCells

        c = data(iCell);
        %cellName = c.tfile_filename_prefix;
        %cellSimilarity = c.angle_index;

        acrossIndices = find( (c.context_1 ~= c.context_2) == 1 );
        withinIndices = find( (c.context_1 == c.context_2) == 1 );

        % Some may be NAN
        va = c.angle_value(acrossIndices);
        va(isnan(va)) = [];

        vw = c.angle_value(withinIndices);
        vw(isnan(vw)) = [];

        alignedMapSimilarityAcross = [alignedMapSimilarityAcross, va];
        alignedMapSimilarityWithin = [alignedMapSimilarityWithin, vw];
    end % iCell

    alignedMapSimilarityToShuffle = [alignedMapSimilarityAcross, alignedMapSimilarityWithin];
    alignedMapSimilarityShuffled = alignedMapSimilarityToShuffle(randperm(length(alignedMapSimilarityToShuffle)));

    x = linspace(-1,1,10001);

    sa = sort(alignedMapSimilarityAcross);
    %sax = unique(sa);
    nsax = zeros(size(x));

    sw = sort(alignedMapSimilarityWithin);
    %swx = unique(sw);
    nswx = zeros(size(x));

    ss = sort(alignedMapSimilarityShuffled);
    %ssx = unique(ss);
    nssx = zeros(size(x));

    for i = 1:length(x)
        nsax(i) = sum( (sa >= x(1)) & (sa <= x(i)) );
        nswx(i) = sum( (sw >= x(1)) & (sw <= x(i)) );
        nssx(i) = sum( (ss >= x(1)) & (ss <= x(i)) );
    end

    psax = nsax ./ max(nsax);
    pswx = nswx ./ max(nswx);
    pssx = nssx ./ max(nssx);

    % Figure
    h = figure;
    plot(x, psax, 'r-')
    hold on
    plot(x, pswx, 'b-')
    plot(x, pssx, 'k-')
    xlabel('Similarity')
    ylabel('Cumulative Proportion')
    grid on
    grid minor
    legend({'across', 'within', 'shuffled'})
    
    title(sprintf('Best Fit 0/180: %s', obj.experiment.subjectName), 'interpreter', 'none')
    
    % Save the figure
    outputFolder = fullfile(session.analysisFolder, 'best_fit_0_180');
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder)
    end
    F = getframe(h);
    fnPrefix = sprintf('%s_%s_across_within_0_180_similarity', obj.experiment.subjectName, session.name);
    imwrite(F.cdata, fullfile(outputFolder, sprintf('%s.png', fnPrefix)), 'png')
    savefig(h, fullfile(outputFolder, sprintf('%s.fig', fnPrefix)));
    saveas(h, fullfile(outputFolder, sprintf('%s.svg', fnPrefix)), 'svg');
    print('-painters', '-depsc', fullfile(outputFolder,sprintf('%s.eps', fnPrefix)))
    close(h);
end % function