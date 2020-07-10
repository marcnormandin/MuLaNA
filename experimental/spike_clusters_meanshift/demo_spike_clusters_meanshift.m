% run this in a directory that has all of the placemaps

T = get_tetrode_clusters();
for iT = 1:length(T)
    tet = T(iT).tetrode{1};
    clusters = T(iT).clusters;
    for iC = 1:length(clusters)
        dataFiles = dir(sprintf('%s_%s_*_mltetrodeplacemaps.mat', tet, clusters{iC}));
        numFiles = length(dataFiles);
        h = figure('position', get(0, 'screensize'));
        %colours = ['r', 'g', 'b', 'm'];
        numColours = numFiles; %length(colours);
        colours = distinguishable_colors(numColours);

        for iFile = 1:numFiles
            file = dataFiles(iFile);
            data = load(fullfile(file.folder, file.name));
            pm = data.mltetrodeplacemap;
            spike_x = pm.passed_spike_x;
            spike_y = pm.passed_spike_y;
            spike_ts_ms = pm.passed_spike_ts_ms;
            spike_metric = diff(spike_x).^2 + diff(spike_y).^2 + diff(spike_ts_ms/1000.0).^2;
            numSpikes = length(spike_x);
            subplot(1,numFiles,iFile)
            X = zeros(numSpikes,2);
            X(:,1) = spike_x(:);
            X(:,2) = spike_y(:);
            [x] = cluster(X);
            %hold on
            xr = unique(round(x,1), 'rows');
            %plot(x(:,1), x(:,2), 'ks', 'markerfacecolor', 'k', 'markersize', 10)
            %hold on
            plot(xr(:,1), xr(:,2), 's', 'color', colours(iFile,:), 'markerfacecolor', colours(iFile,:), 'markersize', 10)
            hold on
            %plot(spike_x, spike_y, 'o', 'color', colours(iFile,:), 'markerfacecolor', colours(iFile,:))
            grid on
            grid minor
            a = axis;

            axis equal tight
            xlim([0, 36])
            ylim([0, 36])
            %axis tight off equal
            %title(file.name)
            %axis off
        end
    end
end

function [T] = get_tetrode_clusters()

matches = dir('TT*_mltetrodeplacemaps.mat');
tetrode = {};
for iMatch = 1:length(matches)
    s = split(matches(iMatch).name, '_');
    tetrode{end+1} = s{1};
    %cluster{end+1,:} = s{1:2};
end
tetrode = unique(tetrode);

T = struct('tetrode', {}, 'clusters', {});
for iTetrode = 1:length(tetrode)
    matches = dir(sprintf('%s_*_mltetrodeplacemaps.mat', tetrode{iTetrode}));
    clusters = {};
    for iMatch = 1:length(matches)
        s = split(matches(iMatch).name, '_');
        clusters{end+1} = s{2};
    end
    clusters = unique(clusters);
    
    T(iTetrode).tetrode = tetrode(iTetrode);
    T(iTetrode).clusters = clusters;
end

end % function

function [x] = cluster(X)
    numSamples = size(X,1);
    DMAX = 4;
    x = X;

    numIterations = 10;
    for iIteration = 1:numIterations

        for iSample = 1:numSamples
            m  = [0, 0]; % mean shift
            mn = [0, 0]; % numerator
            md = 0; % denominator

            % compute the distance
            for jSample = 1:numSamples
                d = sqrt( (x(iSample,1) - x(jSample,1)).^2 + (x(iSample,2) - x(jSample,2)) );
                if d <= DMAX
                    k = mvnpdf([x(jSample,1)-x(iSample,1), x(jSample,2) - x(iSample,2)],[0,0],[4 0; 0 4]);
                    mn = mn + k .* x(jSample,:);
                    md = md + k;
                end
            end
            m = mn ./ md;
            x(iSample,:) = m;
        end
    end
end % function