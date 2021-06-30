function [bfoUsingCorrelations] = ml_core_compute_bfo_90(placemaps, bfoType)
    maxId = size(placemaps,1);
    numTrials = size(placemaps,2);

    perCell = struct('v_all', [], 'vind_all', []);

    for gid = 1:maxId
        perCell(gid).v_all = [];
        perCell(gid).vind_all = [];

        for iTrial1 = 1:numTrials
            pm1 = placemaps{gid, iTrial1};

            if isempty(pm1) || ~any(pm1, 'all')
                continue; % skip
            end

            W1 = ones(size(pm1));
            W1(pm1 == 0) = nan;

            if strcmpi(bfoType, 'unbiased')
                iTrial2Start = 1;
            else
                iTrial2Start = iTrial1+1;
            end
            
            for iTrial2 = iTrial2Start:numTrials

                pm2 = placemaps{gid, iTrial2};
                if isempty(pm2) || ~any(pm2, 'all')
                    continue; % skip
                end
                W2 = ones(size(pm2));
                W2(pm2 == 0) = nan;

                if iTrial1 ~= iTrial2

                    numRotations = 4;
                    r = zeros(1,numRotations);
                    for k = 1:numRotations
                        % Rotate T2 counter-clockwise
                        pm2Rot = rot90(pm2, k-1);
                        W2Rot = rot90(W2, k-1);

                        %a1 = find(W1 == 1);
                        %a2 = find(W2Rot == 1);

                        %a = intersect(a1, a2);
                        a = 1:numel(W1); % Use all of the map area

                        x1 = pm1(a);
                        x2 = pm2Rot(a);

                        x1 = reshape(x1, numel(x1), 1);
                        x2 = reshape(x2, numel(x2), 1);


                        r(k) = corr(x1, x2);
                    end
                    mv = max(r);
                    mi = find(r == mv);
                    vn = mv;
                    vindn = mi;
                else
                    % To not be biased include the map with itself, but we can't
                    % use the correlation coefficient function because the
                    % standard deviation is 0 so will give NAN.
                    if strcmpi(bfoType, 'unbiased')
                        vn = 1;
                        vindn = 1;
                    else
                        continue;
                    end
                end

                if ~isnan(vn)
                    mi = vindn;
                    perCell(gid).v_all(end+1) = vn;
                    prev = perCell(gid).vind_all;
                    perCell(gid).vind_all = [prev, mi];
                end
            end
        end

    end

    hc = histcounts([perCell.vind_all], 1:5);
    bfoUsingCorrelations = hc ./ sum(hc) * 100;

end % function