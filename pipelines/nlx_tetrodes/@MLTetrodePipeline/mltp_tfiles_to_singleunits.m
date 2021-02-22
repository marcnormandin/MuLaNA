function mltp_tfiles_to_singleunits(obj, session)
        % Due to the problem with the 32bit vs 64bit, we need
        % to load the NLX timestamps for comparison
        nvtFilename = fullfile(session.getSessionDirectory(), obj.Experiment.getNvtFilename());
        [nlxNvtTimeStamps_mus, ~, ~, ~, ~, ~, ~] = Nlx2MatVT(  nvtFilename, [1, 1, 1, 1, 1, 1], 1, 1, 1 );

        fl = dir(fullfile(session.getSessionDirectory(), 'TT*.t'));
        tfiles = { fl.name };
        for iFile = 1:length(tfiles)
            mclustTFilename = tfiles{iFile};
            fprintf('Processing tfile ( %s )\n', mclustTFilename);
            spikeTimes_mus = ml_nlx_load_mclust_spikes_as_mus(nlxNvtTimeStamps_mus, fullfile(session.getSessionDirectory(), mclustTFilename), obj.Experiment.getTFileBits());

            % We will store the results in this
            spikes = [];
            
%             for iTrial = 1:session.getNumTrials()
%                 trial = session.getTrial(iTrial);
            for iTrial = 1:session.getNumTrialsToUse()
                trial = session.getTrialToUse(iTrial);
                
                % Load the trials data to get the timestamps for it
                trialFnvtFilename = fullfile(session.getAnalysisDirectory(), sprintf('trial_%d_fnvt.mat', trial.getTrialId()));
                data = load(trialFnvtFilename);
                trialTimeStamps_mus = data.trial.timeStamps_mus;
                
                % Associate the spike times with the current trial if they
                % happened during it.
                spikes(iTrial).trialSpikeTimes_mus = spikeTimes_mus(find(spikeTimes_mus >= trialTimeStamps_mus(1) & spikeTimes_mus <= trialTimeStamps_mus(end)));
                spikes(iTrial).numSpikes = length(spikes(iTrial).trialSpikeTimes_mus);
                spikes(iTrial).trial_id = trial.getTrialId();
            end

            % save the cell data
            fnPrefix = split(mclustTFilename,'.'); 
            singleunit.tfileName = mclustTFilename;
            singleunit.cellName = fnPrefix{1}; % eg. TT3_2
            singleunit.spikeTimes_mus = spikeTimes_mus; % All the spike timestamps, but not split into trials
            singleunit.trialSpikes = spikes;
            singleunit.numTrials = session.getNumTrials();

            singleunit.sessionName = session.getName();
            singleunit.subjectName = obj.Experiment.getAnimalName();
            singleunit.dataset = obj.Experiment.getExperimentName();

            % Assuming that the analysis folder has already
            % been made (which it should have)
            outputFilename = fullfile(session.getAnalysisDirectory(), sprintf('%s_singleunit.mat', singleunit.tfileName));
            save(outputFilename, 'singleunit');
        end % iFile (a mclust t-file)    
    end % function