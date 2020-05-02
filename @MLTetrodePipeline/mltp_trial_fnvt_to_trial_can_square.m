function mltp_trial_fnvt_to_trial_can_square(obj, session)

% Set whether or not this is being called because the true arena shape is a
% square or because it is needed for the 90 degree correlations.

            if obj.verbose
                fprintf('Converting the trial fixed position data to canonical coordinates using the arena ROI.\n');
            end

            sr = session.sessionRecord;
            ti = sr.getTrialsToProcess();
            for iTrial = 1:sr.getNumTrialsToProcess()
                trialId = ti(iTrial).id;
                
                % Load the trial position data
                trialFnvtFilename = fullfile(session.analysisFolder, sprintf('trial_%d_fnvt.mat', trialId));
                fprintf('Loading %s ... ', trialFnvtFilename);
                data = load(trialFnvtFilename);
                fprintf('done!\n');
                trial = data.trial;

                % Load the trial ROI
                arenaRoiFilename = fullfile(session.rawFolder, sprintf('trial_%d_arenaroi.mat', trialId));
                fprintf('Loading %s ... ', arenaRoiFilename);
                data = load(arenaRoiFilename);
                fprintf('done!\n');
                arenaroi = data.arenaroi;

                
                % CAUTION: The transformed points will not all be within
                % the "bounds"

                canon.bounds_x = bounds_x;
                canon.bounds_y = bounds_y;
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