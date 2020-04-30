function mltp_tfiles_to_singleunits_canon_square(obj, session)
        % Due to the problem with the 32bit vs 64bit, we need
        % to load the NLX timestamps for comparison
        nvtFilename = fullfile(session.rawFolder, obj.config.nvt_filename);
        [nlxNvtTimeStamps_mus, ~, ~, ~, ~, ~, ~] = Nlx2MatVT(  nvtFilename, [1, 1, 1, 1, 1, 1], 1, 1, 1 );

        fl = dir(fullfile(session.rawFolder, 'TT*.t'));
        tfiles = { fl.name };
        for iFile = 1:length(tfiles)
            mclustTFilename = tfiles{iFile};
            spikeTimes_mus = ml_nlx_load_mclust_spikes_as_mus(nlxNvtTimeStamps_mus, fullfile(session.rawFolder, mclustTFilename), obj.experiment.info.mclust_tfile_bits);

            spikes = [];
            sr = session.sessionRecord;
            ti = sr.getTrialsToProcess();
            for iTrial = 1:sr.getNumTrialsToProcess()
                trialId = ti(iTrial).id;
                
                data = load(fullfile(session.analysisFolder, sprintf('trial_%d_canon_square.mat', trialId)));

                t = data.canon;
                spikes(trialId).trialSpikeTimes_mus = spikeTimes_mus(find(spikeTimes_mus >= t.timeStamps_mus(1) & spikeTimes_mus <= t.timeStamps_mus(end)));
                spikes(trialId).dt_s = diff([t.timeStamps_mus(1); spikes(trialId).trialSpikeTimes_mus(:)]) / 10^6;
                spikes(trialId).rate = 1 ./spikes(trialId).dt_s;

                spikes(trialId).numSpikes = length(spikes(trialId).trialSpikeTimes_mus);
                trialTimeTotal_s = (t.timeStamps_mus(end) - t.timeStamps_mus(1)) / 10^6;

                spikes(trialId).meanFiringRateHz = spikes(trialId).numSpikes / trialTimeTotal_s;

                % This should use interpolation
%                 spikes(trialId).indices = [];
%                 for iSpike = 1:length(spikes(trialId).rate)
%                     spikes(trialId).indices(iSpike,1) = find(t.timeStamps_mus >= spikes(trialId).trialSpikeTimes_mus(iSpike), 1, 'first');
%                 end
% 
%                 % Record the position of the spikes
%                 spikes(trialId).pos.x = t.pos.x(spikes(trialId).indices(:));
%                 spikes(trialId).pos.y = t.pos.y(spikes(trialId).indices(:));
                spikes(trialId).pos.x = interp1( t.timeStamps_mus, t.pos.x,  spikes(trialId).trialSpikeTimes_mus );
                spikes(trialId).pos.y = interp1( t.timeStamps_mus, t.pos.y,  spikes(trialId).trialSpikeTimes_mus );
                spikes(trialId).spe   = interp1( t.timeStamps_mus, t.spe, spikes(trialId).trialSpikeTimes_mus );
                % include angle
            end

            % save the cell data
            fnPrefix = split(mclustTFilename,'.'); 
            singleunit.tfileName = mclustTFilename;
            singleunit.cellName = fnPrefix{1}; % eg. TT3_2
            singleunit.spikeTimes_mus = spikeTimes_mus;
            singleunit.trialSpikes = spikes;
            singleunit.numTrials = session.num_trials_recorded;
            singleunit.sessionName = session.name;
            singleunit.subjectName = obj.experiment.subjectName;
            singleunit.dataset = obj.experiment.dataset;

            % Assuming that the analysis folder has already
            % been made (which it should have)
            outputFilename = fullfile(session.analysisFolder, sprintf('%s_singleunit_canon_square.mat', singleunit.tfileName));
            save(outputFilename, 'singleunit');
        end % iFile (a mclust t-file)
    end % function