function mltp_tfiles_to_singleunits(obj, session)
        % Due to the problem with the 32bit vs 64bit, we need
        % to load the NLX timestamps for comparison
        nvtFilename = fullfile(session.rawFolder, obj.config.nvt_filename);
        [nlxNvtTimeStamps_mus, ~, ~, ~, ~, ~, ~] = Nlx2MatVT(  nvtFilename, [1, 1, 1, 1, 1, 1], 1, 1, 1 );

        fl = dir(fullfile(session.rawFolder, 'TT*.t'));
        tfiles = { fl.name };
        for iFile = 1:length(tfiles)
            mclustTFilename = tfiles{iFile};
            fprintf('Processing tfile ( %s )\n', mclustTFilename);
            spikeTimes_mus = ml_nlx_load_mclust_spikes_as_mus(nlxNvtTimeStamps_mus, fullfile(session.rawFolder, mclustTFilename), obj.experiment.info.mclust_tfile_bits);

            
            % We will store the results in this
            spikes = [];
            
            sr = session.sessionRecord;
            ti = sr.getTrialsToProcess();
            for iTrial = 1:sr.getNumTrialsToProcess()
                trialId = ti(iTrial).id;
                
                % Load the trials data to get the timestamps for it
                trialFnvtFilename = fullfile(session.analysisFolder, sprintf('trial_%d_fnvt.mat', trialId));
                data = load(trialFnvtFilename);
                trialTimeStamps_mus = data.trial.timeStamps_mus;
                
                % Associate the spike times with the current trial if they
                % happened during it.
                spikes(trialId).trialSpikeTimes_mus = spikeTimes_mus(find(spikeTimes_mus >= trialTimeStamps_mus(1) & spikeTimes_mus <= trialTimeStamps_mus(end)));
                spikes(trialId).numSpikes = length(spikes(trialId).trialSpikeTimes_mus);
            end

            % save the cell data
            fnPrefix = split(mclustTFilename,'.'); 
            singleunit.tfileName = mclustTFilename;
            singleunit.cellName = fnPrefix{1}; % eg. TT3_2
            singleunit.spikeTimes_mus = spikeTimes_mus; % All the spike timestamps, but not split into trials
            singleunit.trialSpikes = spikes;
            singleunit.numTrials = sr.getNumTrialsToProcess();

            singleunit.sessionName = session.name;
            singleunit.subjectName = obj.experiment.subjectName;
            singleunit.dataset = obj.experiment.dataset;

            % Assuming that the analysis folder has already
            % been made (which it should have)
            outputFilename = fullfile(session.analysisFolder, sprintf('%s_singleunit.mat', singleunit.tfileName));
            save(outputFilename, 'singleunit');
        end % iFile (a mclust t-file)    
    end % function