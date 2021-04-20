function mltp_trial_fnvt_to_trial_can_movement(obj, session)
    % This function calculates the movement in cm/s for each trial. We need
    % to store this because when we map a rectangle to a square for the 90
    % degree correlations the spike maps has a minimum speed threshold,
    % which should come from the true speed, not the speed after mapping
    % from a rectangle to a square.

    if obj.isVerbose()
        fprintf('Computing the movment in cm/s using the arena ROI.\n');
    end

%     for iTrial = 1:session.getNumTrials()
%         trial = session.getTrial(iTrial);
    for iTrial = 1:session.getNumTrialsToUse()
        trial = session.getTrialToUse(iTrial);

        % Load the trial position data (fixed)
        trialFnvtFilename = fullfile(session.getAnalysisDirectory(), sprintf('trial_%d_fnvt.mat', trial.getTrialId()));
        fprintf('Loading %s ... ', trialFnvtFilename);
        data = load(trialFnvtFilename);
        fprintf('done!\n');
        tdata = data.trial;

        % Load the trial ROI
        arenaRoiFilename = fullfile(session.getSessionDirectory(), sprintf('trial_%d_arenaroi.mat', trial.getTrialId()));
        fprintf('Loading %s ... ', arenaRoiFilename);
        data = load(arenaRoiFilename);
        fprintf('done!\n');
        arenaroi = data.arenaroi;

        % Construct the appropriate arena. All the shapes have 4 control
        % points that serve as references.
        refP = reshape(arenaroi.xVertices, 1, 4);
        refQ = reshape(arenaroi.yVertices, 1, 4);
        a = obj.Experiment.getArenaGeometry();
        if strcmpi(a.shape, 'rectangle')
            arena = MLArenaRectangle([refP; refQ], a.x_length_cm , a.y_length_cm);
        elseif strcmp(a.shape, 'square')
            arena = MLArenaSquare([refP; refQ], a.length_cm);
        else
            error('Inappropriate shape (%s). Must be square or rectangle', a.shape);
        end

        % Transform positions from video to canonical (pixels to
        % cm)
        [x_cm, y_cm] = arena.tranformVidToCanonPoints(tdata.extractedX, tdata.extractedY);

        % Compute the speed in the canonical frame (in cm/s)
        timestamps_ms = tdata.timeStamps_mus ./ 10^3;
        [speed_cm_per_s, speed_smoothed_cm_per_s, vx, vy, vx_smoothed, vy_smoothed] ...
            = ml_core_compute_motion(x_cm, y_cm, timestamps_ms, obj.Config.velocity_lowpass_wpass);

        % Store the values to be saved
        movement.sequenceId = trial.getSequenceId();
        movement.trialId = trial.getTrialId();
        movement.arena = arena;
        movement.arenaShape = arena.getShapeType();
        [movement.boundsX, movement.boundsY] = arena.getCanonicalBounds();
        movement.x_px = tdata.extractedX; % store the video coordinates
        movement.y_px = tdata.extractedY; % store the video coordinates
        movement.x_cm = x_cm;
        movement.y_cm = y_cm;
        movement.isInsideArena = arena.inInterior( x_cm, y_cm );
        movement.timestamps_ms = timestamps_ms;
        movement.speed_cm_per_s = speed_cm_per_s;
        movement.speed_smoothed_cm_per_s = speed_smoothed_cm_per_s;
        movement.vx = vx;
        movement.vy = vy;
        movement.vx_smoothed = vx_smoothed;
        movement.vy_smoothed = vy_smoothed;

        trialCanonFilename = fullfile(session.getAnalysisDirectory(), sprintf('trial_%d_movement.mat', trial.getTrialId()));
        fprintf('Saving %s ... ', trialCanonFilename);
        save(trialCanonFilename, 'movement')
        fprintf('done!\n');
    end
end % function
