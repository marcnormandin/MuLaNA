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
            for iTrial = 1:session.num_trials_recorded
                data = load(fullfile(session.analysisFolder, sprintf('trial_%d_canon_square.mat', iTrial)));

                t = data.canon;
                spikes(iTrial).trialSpikeTimes_mus = spikeTimes_mus(find(spikeTimes_mus >= t.timeStamps_mus(1) & spikeTimes_mus <= t.timeStamps_mus(end)));
                spikes(iTrial).dt_s = diff([t.timeStamps_mus(1); spikes(iTrial).trialSpikeTimes_mus(:)]) / 10^6;
                spikes(iTrial).rate = 1 ./spikes(iTrial).dt_s;

                spikes(iTrial).numSpikes = length(spikes(iTrial).trialSpikeTimes_mus);
                trialTimeTotal_s = (t.timeStamps_mus(end) - t.timeStamps_mus(1)) / 10^6;

                spikes(iTrial).meanFiringRateHz = spikes(iTrial).numSpikes / trialTimeTotal_s;

                % This should use interpolation
%                 spikes(iTrial).indices = [];
%                 for iSpike = 1:length(spikes(iTrial).rate)
%                     spikes(iTrial).indices(iSpike,1) = find(t.timeStamps_mus >= spikes(iTrial).trialSpikeTimes_mus(iSpike), 1, 'first');
%                 end
% 
%                 % Record the position of the spikes
%                 spikes(iTrial).pos.x = t.pos.x(spikes(iTrial).indices(:));
%                 spikes(iTrial).pos.y = t.pos.y(spikes(iTrial).indices(:));
                spikes(iTrial).pos.x = interp1( t.timeStamps_mus, t.pos.x,  spikes(iTrial).trialSpikeTimes_mus );
                spikes(iTrial).pos.y = interp1( t.timeStamps_mus, t.pos.y,  spikes(iTrial).trialSpikeTimes_mus );
                spikes(iTrial).spe   = interp1( t.timeStamps_mus, t.spe, spikes(iTrial).trialSpikeTimes_mus );
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