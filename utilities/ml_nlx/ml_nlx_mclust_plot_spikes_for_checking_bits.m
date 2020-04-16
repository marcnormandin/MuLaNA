function [h] = ml_nlx_mclust_plot_spikes_for_checking_bits( nvtFilename, tFilenameFull )

    tmp = split(tFilenameFull, filesep);
    tFilename = tmp{end};
    
    [TimeStamps_mus, ExtractedX, ExtractedY, ExtractedAngle, Targets, Points, Header] = Nlx2MatVT(  nvtFilename, [1, 1, 1, 1, 1, 1], 1, 1, 1 );

    x = ml_nlx_mclust_load_spikes_32bit( tFilenameFull );
    ts_mus_32 = x .* 10^6;
    x = ml_nlx_mclust_load_spikes_64bit( tFilenameFull );
    ts_mus_64 = x .* 10^6;

    h = figure;

    % 32 bits
    ax(1) = subplot(2,1,1);
    rectangle('Position', [0, TimeStamps_mus(1), length(ts_mus_32), TimeStamps_mus(end)-TimeStamps_mus(1)], ...
                    'Curvature', 0.0, ...
                    'FaceColor', [0, 1, 0, 0.2], ...
                    'EdgeColor', [1, 0, 0, 0.2]);
    hold on
    plot(ts_mus_32, 'b.')
    title(sprintf('%s loaded as 32 bit', tFilename), 'interpreter', 'none')
    grid on
    ylabel('spike time [microseconds]')
    legend({sprintf('%d spikes', length(ts_mus_32))}, 'location', 'southeast')

    % 64 bits
    ax(2) = subplot(2,1,2);
    rectangle('Position', [0, TimeStamps_mus(1), length(ts_mus_32), TimeStamps_mus(end)-TimeStamps_mus(1)], ...
                    'Curvature', 0.0, ...
                    'FaceColor', [0, 1, 0, 0.2], ...
                    'EdgeColor', [1, 0, 0, 0.2]);
    hold on
    plot(ts_mus_64, 'r.')
    ylabel('spike time [microseconds]')
    legend({sprintf('%d spikes', length(ts_mus_64))}, 'location', 'southeast')
    title(sprintf('%s loaded as 64 bit', tFilename), 'interpreter', 'none')
    xlabel('spike #')
    grid on

    linkaxes(ax, 'x')
    axis tight

end % function
