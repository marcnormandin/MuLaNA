function mltp_trial_nvt_to_trial_fnvt(obj, session)
            if obj.verbose
                fprintf('Fixing the trial data.\n');
            end

            for iTrial = 1:session.num_trials_recorded
                trialNvtFilename = fullfile(session.analysisFolder, sprintf('trial_%d_nvt.mat', iTrial));
                fprintf('Loading %s ... ', trialNvtFilename);
                data = load(trialNvtFilename);
                t = data.trial;
                fprintf('done!\n');

                % Load the ROI so that we can exclude points (set them to
                % zero if outside the ROI).
                troiFilename = fullfile(session.rawFolder, sprintf('trial_%d_arenaroi.mat', iTrial));
                if ~isfile(troiFilename)
                    error('Required file (%s) does not exist.', troiFilename);
                end
                tmp = load(troiFilename);
                xBounds = tmp.arenaroi.xVertices;
                yBounds = tmp.arenaroi.yVertices;
                inROI = inpolygon(t.extractedX, t.extractedY, xBounds, yBounds);
                outsideIndices = find(inROI == 0);
                t.extractedX(outsideIndices) = 0;
                t.extractedY(outsideIndices) = 0;
                t.extractedAngle(outsideIndices) = 0;
                
                %allIndices = 1:t.numSamples;

                % Find the indices that are definitely bad
                %badIndices = unique([find(t.ExtractedX == 0); find(t.ExtractedY == 0)]);
                %goodIndices = sort(setdiff(allIndices, badIndices));

                % Use the good values for the interpolation
                %interpX = movmean(interp1(goodIndices, smoothedX(goodIndices), allIndices), WS);
                %interpY = movmean(interp1(goodIndices, smoothedY(goodIndices), allIndices), WS);
                %interpAngle = movmean(interp1(goodIndices, smoothedAngle(goodIndices), allIndices), WS);
                interpX = ml_nlx_nvt_fix_extracted_array(t.extractedX);
                interpY = ml_nlx_nvt_fix_extracted_array(t.extractedY);
                interpAngle = ml_nlx_nvt_fix_extracted_array(t.extractedAngle);

                trial.extractedX = interpX;
                trial.extractedY = interpY;
                trial.extractedAngle = interpAngle;

                trial.numSamples = t.numSamples;
                trial.startIndex = t.startIndex;
                trial.stopIndex = t.stopIndex;
                trial.timeStamps_mus = t.timeStamps_mus;
                trial.targets = t.targets;
                trial.points = t.points;
                trial.header = t.header;

                trialFnvtFilename = fullfile(session.analysisFolder, sprintf('trial_%d_fnvt.mat', iTrial));
                fprintf('Saving %s ... ', trialFnvtFilename);
                save(trialFnvtFilename, 'trial')
                fprintf('done!\n');
            end
        end % function