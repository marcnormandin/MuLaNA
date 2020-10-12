function [h] = ml_nlx_auto_placemaps(tFilename, t_mus, x_px, y_px, trialSeparationSeconds, numBits, ...
    L_cm, W_cm, cm_per_bin, sigma_cm, hsize_cm)
    nlxNvtTimeStamps_mus = trialSeparationSeconds*10^6;

    %behav = csvread('behaviour_d7.csv');

    t = reshape(t_mus, numel(t_mus), 1);
    x = reshape(x_px, numel(x_px), 1);
    y = reshape(y_px, numel(y_px), 1);

    % t = behav(:,1);
    % x = behav(:,2);
    % y = behav(:,3);


    %spikeTimes = csvread('TT2_02.csv');
    spikeTimes = ml_nlx_load_mclust_spikes_as_mus(nlxNvtTimeStamps_mus, tFilename, numBits);
    %spikeTimes = spikeTimes / 10 * 1000;

    % Convert to seconds
    t = t / 10^6;
    spikeTimes = spikeTimes / 10^6;

    % Offset to the start of the trial
    t = t - t(1);
    spikeTimes = spikeTimes - t(1); % This should be t(1) and not spikeTimes(1), but trials 1 and 2 have no spikes...



    ddt = median(diff(t));
    dt = [ddt; diff(t)];
    jumps = find(dt > 10);
    ends = [1; jumps; length(t)];
    numTrials = length(ends)-1;

%     p = 2; q = 6;
    %figure
%     i = 1;
    trial = struct('t', [], 'px', [], 'py', [], 'st', [], 'sx', [], 'sy', []);

    for iTrial = 1:numTrials
        %subplot(p,q,iTrial)

        tt = t(ends(iTrial):ends(iTrial+1)-1);
        tx = x(ends(iTrial):ends(iTrial+1)-1);
        ty = y(ends(iTrial):ends(iTrial+1)-1);

        % Remove the (0,0)
        badi = union( find(tx == 0), find(ty == 0) );
        tt(badi) = [];
        tx(badi) = [];
        ty(badi) = [];

        % Compute the centroid
        cx = mean(tx);
        cy = mean(ty);
        d = sqrt( (tx-cx).^2 + (ty-cy).^2 );

        % Remove points that are too far from the centroid
        badi = find(d > 100);
        tt(badi) = [];
        tx(badi) = [];
        ty(badi) = [];

        %subplot(1,2,1)
        %hist(d,100)

        %kmine = MyConvHullAnimated(tx, ty, false);
        %kmine = kmine(end:-1:1)';
        k = convhull(tx, ty);
        %k = kmine;
        %break

%         figure
%         subplot(1,2,1)
% 
% 
%         plot(tx(k), ty(k), 'k-o', 'markerfacecolor', 'y', 'linewidth', 4, 'markersize',10)
%         hold on
%         plot([tx(k(end)) tx(k(1))], [ty(k(end)) ty(k(1))], 'k-o', 'markerfacecolor', 'y', 'linewidth', 4, 'markersize',10)
% 
% 
%         plot(tx, ty, 'k.')
%         hold on

        % Find the minimum rectangle
        % For every pair of points, compute the min and max in each dimension
        % after projecting
        numK = length(k);
        numP = length(tx);
        kx = tx(k);
        ky = ty(k);
        A = cell(numK-1,9);
        for k = 1:numK-1
            ux = kx(k+1) - kx(k);
            uy = ky(k+1) - ky(k);
            mu = sqrt(ux.^2 + uy.^2);
            ux = ux ./ mu; % make unit vector
            uy = uy ./ mu;
            vx = -uy;
            vy = ux;

            px = [];
            py = [];
            for i = 1:numP
                px(end+1) = sum((tx(i)-kx(k)) * ux + (ty(i)-ky(k))*uy);
                py(end+1) = sum((tx(i)-kx(k)) * vx + (ty(i)-ky(k))*vy);
            end

            A{k,1} = (max(px)-min(px)) * (max(py)-min(py));
            A{k,2} = min(px);
            A{k,3} = max(px);
            A{k,4} = min(py);
            A{k,5} = max(py);
            A{k,6} = ux;
            A{k,7} = uy;
            A{k,8} = vx;
            A{k,9} = vy;
        end
        [minA, j] = min([A{:,1}]);
        r = zeros(4,2);
    %     r(1,:) = [kx(j) + A{j,6}*A{j,2}, ky(j) + A{j,7}*A{j,2}];
    %     r(2,:) = [kx(j) + A{j,6}*A{j,3}, ky(j) + A{j,7}*A{j,3}];
    %     r(3,:) = [kx(j) + A{j,8}*A{j,4}, ky(j) + A{j,9}*A{j,4}];
    %     r(4,:) = [kx(j) + A{j,8}*A{j,5}, ky(j) + A{j,9}*A{j,5}];
        r(1,:) = [kx(j) + A{j,6}*A{j,2}, ky(j) + A{j,7}*A{j,2}];
        r(2,:) = [kx(j) + A{j,6}*A{j,3}, ky(j) + A{j,7}*A{j,3}];
        r(4,:) = [r(1,1) + A{j,8}*A{j,5}, r(1,2) + A{j,9}*A{j,5}];
        r(3,:) = [r(2,1) + A{j,8}*A{j,5}, r(2,2) + A{j,9}*A{j,5}];

%         plot(r(:,1), r(:,2), 'b-', 'linewidth', 4)
%         plot(r(1:2,1), r(1:2,2), 'r-', 'linewidth', 8)
%         plot([r(end,1), r(1,1)], [r(end,2), r(1,2)], 'b-', 'linewidth', 4)




        % plot the spikes
%         hold on
        si = find(spikeTimes >= tt(1) & spikeTimes <= tt(end));
        st = spikeTimes(si);
        sx = [];
        sy = [];
        for i=1:length(si)
            jj = find(tt >= st(i), 1, 'first');
            sx(end+1) = tx(jj);
            sy(end+1) = ty(jj);
        end
%         plot(sx, sy, 'ro', 'markerfacecolor', 'r')

%         title(sprintf('Trial %d', iTrial))
%         set(gca, 'ydir', 'reverse')
%         axis equal tight
%         grid on
%         a = axis;
%         axis([a(1)-10, a(2)+10,a(3)-10,a(4)+10])
% 
%         subplot(1,2,2)

        % Now transform the data so the rectangles are axis aligned
        ax = r(2,1) - r(1,1);
        ay = r(2,2) - r(1,2);
        ma = sqrt(ax.^2 + ay.^2);
        ax = ax ./ ma;
        ay = ay ./ ma;
        bx = r(4,1) - r(1,1);
        by = r(4,2) - r(1,2);
        mb = sqrt(bx.^2 + by.^2);
        bx = bx ./ mb;
        by = by ./ mb;

        qx = zeros(numP,1);
        qy = zeros(numP,1);
        for i = 1:numP
            qx(i) = sum( (tx(i)-r(1,1))*ax + (ty(i)-r(1,2))*ay );
            qy(i) = sum( (tx(i)-r(1,1))*bx + (ty(i)-r(1,2))*by );
        end

%         plot(qx, qy, 'k.')
%         hold on
        sx = [];
        sy = [];
        for i=1:length(si)
            jj = find(tt >= st(i), 1, 'first');
            sx(end+1) = qx(jj);
            sy(end+1) = qy(jj);
        end
%         plot(sx, sy, 'ro', 'markerfacecolor', 'r')
%         axis equal tight
%         set(gca, 'ydir', 'reverse')

        trial(iTrial).t = tt;
        trial(iTrial).px = qx;
        trial(iTrial).py = qy;

        trial(iTrial).st = st;
        trial(iTrial).sx = sx;
        trial(iTrial).sy = sy;
    end



    % Make the placemaps
%     L_cm = 30.0;
%     W_cm = 20.0;
%     cm_per_bin = 2.0;
%     sigma_cm = 3.0;
%     hsize_cm=30;
    sigma_bin = sigma_cm / cm_per_bin;
    hsize_bin = ceil(hsize_cm / cm_per_bin);
    if mod(hsize_bin,2) ~= 1
        hsize_bin = hsize_bin + 1;
    end
    kernel = fspecial('gaussian', hsize_bin, sigma_bin);
    kernel = kernel ./ max(kernel, [], 'all');

    h = [];
    
    for iTrial = 1:length(trial)
       lx_px = max(trial(iTrial).px) - min(trial(iTrial).px);
       ly_px = max(trial(iTrial).py) - min(trial(iTrial).py);
       dtm = median(diff(trial(iTrial).t));
       if lx_px > ly_px
           nbinsx = L_cm / cm_per_bin;
           nbinsy = W_cm / cm_per_bin;
           boundsx = [0, L_cm];
           boundsy = [0, W_cm];
           SX = L_cm;
           SY = W_cm;
       else
           nbinsx = W_cm / cm_per_bin;
           nbinsy = L_cm / cm_per_bin;
           boundsx = [0, W_cm];
           boundsy = [0, L_cm];
           SX = W_cm;
           SY = L_cm;
       end

       xi = discretize(trial(iTrial).px, linspace(0, max(trial(iTrial).px), nbinsx));
       yi = discretize(trial(iTrial).py, linspace(0, max(trial(iTrial).py), nbinsy));
       sxi = discretize(trial(iTrial).sx, linspace(0, max(trial(iTrial).px), nbinsx));
       syi = discretize(trial(iTrial).sy, linspace(0, max(trial(iTrial).py), nbinsy));

       Np = histcounts2(xi, yi, 0:nbinsx, 0:nbinsy);
       Ns = histcounts2(sxi, syi, 0:nbinsx, 0:nbinsy);

       T = cell(size(Np));
       for i=1:numel(T)
           T{i} = [];
       end
       st = trial(iTrial).st - trial(iTrial).t(1);
       for i = 1:length(st)
           T{sxi(i), syi(i)} = [T{sxi(i), syi(i)}, st(i)];
       end
       peakRateMap = zeros(size(Np));

       for i = 1:size(T,1)
        for j = 1:size(T,2)
            if length(T{i,j}) > 1
                dt = diff(T{i, j});
                peakRateMap(i,j) = 1./mean(dt);
            end
        end
       end
       peakRateMap(~isfinite(peakRateMap)) = 0;

       occupancy = Np .* dtm;

       %rateMap = zeros(size(Np));
       rateMap = Ns ./ occupancy;
       rateMap(isnan(rateMap)) = 0;
       %rateMaps = imfilter(Ns, kernel) ./ imfilter(occupancy, kernel);
       rateMaps = imfilter(rateMap, kernel);
       rateMaps(~isfinite(rateMaps)) = 0;
       mfr = mean(rateMap(occupancy > 0), 'all');
       pfr = max(rateMap, [], 'all');

       magicNumber1 = mean(rateMap(rateMap > 0), 'all');
       magicNumber2 = mean(rateMaps(rateMaps > 0), 'all');

       mfr2 = length(trial(iTrial).sx) ./ (trial(iTrial).t(end) - trial(iTrial).t(1));
       mfr3 = length(trial(iTrial).sx) ./ (length(trial(iTrial).t)*dtm);

       numSpikes = length(trial(iTrial).sx);
       totalTime = trial(iTrial).t(end) - trial(iTrial).t(1);

       rateMap = rateMap ./ magicNumber1 * mfr2;
       rateMaps = rateMaps ./ magicNumber2 * mfr2;

       h(iTrial) = figure('name', sprintf('%s : T%d', tFilename, iTrial));
       subplot(1,3,1)
       plot(trial(iTrial).px, trial(iTrial).py, 'k.')
       hold on
       plot(trial(iTrial).sx, trial(iTrial).sy, 'ro', 'markerfacecolor', 'r', 'markersize', 4)
       set(gca, 'ydir', 'reverse')
       grid on
       axis equal tight
       title(sprintf('# spikes: %d\n# seconds: %0.3f', numSpikes, totalTime))

       subplot(1,3,2)
       imagesc(fliplr(rateMap));
       colormap jet
       colorbar
       axis equal tight
       title(sprintf('%0.3f | %0.3f vs %0.3f vs %0.3f', pfr, mfr, mfr2, mfr3))

       subplot(1,3,3)
       A = fliplr(rateMaps);
       B=[[A; nan(1,size(A,2))], nan(size(A,1)+1,1)];
       pcolor(B);
       shading interp
       colormap jet
       colorbar
       axis equal tight
       %imagesc(fliplr(rateMaps));
       colormap jet
       colorbar
       axis equal tight
       axis([1, size(A,2), 1, size(A,1)])
       set(gca, 'ydir', 'reverse')
       
       drawnow
    end

    %%
%     kernel = fspecial('gaussian', hsize_bin, sigma_bin);
%     kernel = kernel ./ max(kernel, [], 'all');
% 
%     A= zeros(30,20);
%     A(15,10) = 1;
%     A(15,11) = 1;
%     As = imfilter(A, kernel);
%     figure
%     imagesc(As)
%     colormap jet
%     axis equal tight
% 
%     colorbar

    %%
%     figure
%     %A = fliplr(rateMaps);
%     B=[[A; nan(1,size(A,2))], nan(size(A,1)+1,1)];
%        pcolor(B);
%        shading interp
%        colormap jet
%        colorbar
%        axis equal tight
%        axis([1, size(A,2), 1, size(A,1)])

end % function
