function mulana_savefig(hFig, outputFolder, fnPrefix, formats)
    for iFormat = 1:length(formats)
       format = formats{iFormat};
       fn = [];
       if ismember(format, {'png', 'pdf', 'svg'})
           fn = fullfile(outputFolder, sprintf('%s.%s', fnPrefix, format));
           if ~exist(outputFolder, 'dir')
               mkdir(outputFolder);
           end
           saveas(hFig, fn);
       elseif strcmp(format, 'fig')
           fn = fullfile(outputFolder, sprintf('%s.fig', fnPrefix));
           if ~exist(outputFolder, 'dir')
               mkdir(outputFolder);
           end
           savefig(hFig, fn);
       else
           warning('Can not save figure with the format %s.\n', format);
       end
       
       if ~isempty(fn)
           fprintf('Figure saved: %s\n', fn);
       end
    end
end