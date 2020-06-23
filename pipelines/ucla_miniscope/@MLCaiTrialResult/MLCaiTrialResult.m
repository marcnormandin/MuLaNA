classdef MLCaiTrialResult < handle
    properties (SetAccess = private)
        trialResultsFolder = [];
        neuronFilename;
        scopeFilename;
        behavFilename;
        behavTrackVidFilename;

        behavTrackVid;
        neuronData;
        scopeVideoData;
        behavVideoData;        
    end
    
    methods
        function obj = MLCaiTrialResult( trialResultsFolder )
            
            obj.trialResultsFolder = trialResultsFolder;

            obj.neuronFilename = fullfile(trialResultsFolder, 'neuron.hdf5');
            obj.scopeFilename = fullfile(trialResultsFolder, 'scope.hdf5');
            obj.behavFilename = fullfile(trialResultsFolder, 'behav.hdf5');
            obj.behavTrackVidFilename = fullfile(trialResultsFolder, 'behav_track_vid.hdf5');

            obj.behavTrackVid = ml_cai_behavtrackvid_h5_read( obj.behavTrackVidFilename );
            obj.neuronData = ml_cai_neuron_h5_read( obj.neuronFilename );
            obj.scopeVideoData = ml_cai_scope_h5_read( obj.scopeFilename );
            obj.behavVideoData = ml_cai_behav_h5_read( obj.behavFilename );

            % check for integrity
            numTimesamples = obj.neuronData.num_time_samples;
            if obj.scopeVideoData.num_frames ~= numTimesamples
                error('Number of scope time samples (%d) does not match neuron samples (%d)', obj.scopeVideoData.num_frames, numTimeSamples);
            end

            
            % Compute the calcium events for each neuron
            %for iN = 1:obj.neuronData.num_neurons
            %   obj.neuronData.neuron{iN}.calciumEvents = ml_cai_neuron_calcium_events(obj.neuronData.neuron{iN}, obj.scopeVideoData.timestamp_ms);
            %end
        end % function
        
        function [scope_timestamps_ms] = getScopeTimestampsMs(obj)
           scope_timestamps_ms = obj.scopeVideoData.timestamp_ms; 
        end
        
        function [numNeurons] = getNumNeurons(obj)
            numNeurons = obj.neuronData.num_neurons;
        end % function 
        
        function [neuron] = getNeuronById(obj, iNeuron)
            if iNeuron < 0 || iNeuron > obj.getNumNeurons()
                error('Invalid neuron id. Cannot return neuron.');
            end
            neuron = obj.neuronData.neuron(iNeuron);
        end
        
        function [scopeVideoWidth, scopeVideoHeight] = getScopeVideoDimensions(obj)
            % Return the dimensions of the spatially downsampled and aligned video
            scopeVideoWidth = obj.neuronData.spatial_footprint_j;
            scopeVideoHeight = obj.neuronData.spatial_footprint_i;
        end % function
        
        plotRaster(obj);
        plotSFPs(obj);
        
    end % methods
end % classdef