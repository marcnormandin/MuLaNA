function mltp_trial_fnvt_to_trial_can_rect(obj, session)

            if obj.verbose
                fprintf('Converting the trial fixed position data to canonical coordinates using the arena ROI.\n');
            end

            sr = session.sessionRecord;
            ti = sr.getTrialsToProcess();
            for iTrial = 1:sr.getNumTrialsToProcess()
                trialId = ti(iTrial).id;
                
                trialFnvtFilename = fullfile(session.analysisFolder, sprintf('trial_%d_fnvt.mat', trialId));
                fprintf('Loading %s ... ', trialFnvtFilename);
                data = load(trialFnvtFilename);
                fprintf('done!\n');
                trial = data.trial;

                arenaRoiFilename = fullfile(session.rawFolder, sprintf('trial_%d_arenaroi.mat', trialId));
                fprintf('Loading %s ... ', arenaRoiFilename);
                data = load(arenaRoiFilename);
                fprintf('done!\n');
                arenaroi = data.arenaroi;

                % Must be a 2xN matrix of points
                % The coordinates of the reference points in the video frame (pixels)
                refVidPts = zeros(2,length(arenaroi.xVertices));
                refVidPts(1,:) = arenaroi.xVertices(:);
                refVidPts(2,:) = arenaroi.yVertices(:);

                % The coordinates of the reference points in the canonical frame
                % For the rectangle/square, the feature is at the top/north
%                 a = [obj.experiment.info.arena.width_cm, 0];
%                 b = [0, 0];
%                 c = [0, obj.experiment.info.arena.length_cm];
%                 d = [obj.experiment.info.arena.width_cm, obj.experiment.info.arena.length_cm];
                a = [obj.config.placemaps_rect.bounds_x(2), obj.config.placemaps_rect.bounds_y(1)];
                b = [obj.config.placemaps_rect.bounds_x(1), obj.config.placemaps_rect.bounds_y(1)];
                c = [obj.config.placemaps_rect.bounds_x(1), obj.config.placemaps_rect.bounds_y(2)];
                d = [obj.config.placemaps_rect.bounds_x(2), obj.config.placemaps_rect.bounds_y(2)];
                refCanPts = [a(1), b(1), c(1), d(1); a(2), b(2), c(2), d(2)];

                % Get the transformation matrix
                vtrans = homography_solve(refVidPts, refCanPts);

                % Tranform the subject position
                canonPts = homography_transform([trial.extractedX; trial.extractedY], vtrans);

                % Transform the arena vertices
                xPts = zeros(2,length(arenaroi.xVertices));
                xPts(1,:) = arenaroi.xVertices(:);
                xPts(2,:) = arenaroi.yVertices(:);
                y = homography_transform(xPts, vtrans); % Just to check


                canon.vtrans = vtrans;
                canon.pos.x = canonPts(1,:);
                canon.pos.y = canonPts(2,:);
                % convert the angle
                canon.arenaroi.xVertices = y(1,:);
                canon.arenaroi.yVertices = y(2,:);

                canon.numSamples = trial.numSamples;
                canon.startIndex = trial.startIndex;
                canon.stopIndex  = trial.stopIndex;
                canon.timeStamps_mus = trial.timeStamps_mus;

                % Compute the velocity components in cm / second
                dx = diff(canon.pos.x);
                dy = diff(canon.pos.y);
                dt = diff(canon.timeStamps_mus./10^6);
                vx = dx./dt;
                canon.vel.x = [0, lowpass(vx, obj.config.velocity_lowpass_wpass)];
                vy = dy./dt;
                canon.vel.y = [0, lowpass(vy, obj.config.velocity_lowpass_wpass)];

                % Compute the speed, which is the magnitude of the velocity
                canon.spe = sqrt( canon.vel.x.^2 + canon.vel.y.^2 );
                
                trialCanonFilename = fullfile(session.analysisFolder, sprintf('trial_%d_canon_rect.mat', trialId));
                fprintf('Saving %s ... ', trialCanonFilename);
                save(trialCanonFilename, 'canon')
                fprintf('done!\n');
            end
        end % function