classdef MLCaiNeuron < handle
    properties
        spatial_footprint;
        spikes
        trace_filt;
        trace_raw;
        
        timestamps_ms;
        
        %calciumEvents; % computed from the time series
        
        numTimeSamples;
        neuronId; % Its number in the neuron.hdf5 file
    end % properties
    
    methods
        function obj = MLCaiNeuron( neuronFilename, neuronId, timestamps_ms )
            % Load a single neuron result from 'neuron.hdf5'
            
            % Check that the file exists
            if ~isfile( neuronFilename )
                error('Cannot load from (%s) because it is not a file.', neuronFilename);
            end
            
            % Check that the requested neuron number exists
            numNeurons = h5readatt(neuronFilename, '/', 'num_neurons');
            if neuronId < 0 || neuronId > numNeurons
                error('Requested loading of neuron (%d), but there are only (%d) neurons.', neuronId, numNeurons);
            end
            
            obj.neuronId = neuronId;
            
            ndfFields = {'spatial_footprint', 'spikes', 'trace_filt', 'trace_raw'};
            matFields = ndfFields;
            numFields = length(ndfFields);

            try 
                for iF = 1:numFields
                    fstr = sprintf('/neuron_%d/%s', neuronId, ndfFields{iF});
                    obj.(matFields{iF}) = h5read(neuronFilename, fstr);
                end
            catch e
                error('Error while reading data for neuron (%d) from (%s).', neuronId, neuronFilename);
            end

            obj.numTimeSamples = length(obj.trace_raw);
            
            if isempty(timestamps_ms)
                warning('No timestamps as input so using uniformly space timestamps.');
                
                timestamps_ms = 1:length(obj.trace_raw);
            end
            
            obj.timestamps_ms = timestamps_ms;
            
            %obj.calciumEvents = ml_cai_neuron_calcium_events(
        end % function
        
        function [sfp] = getSpatialFootprint(obj, varargin)
            p = inputParser;
            p.CaseSensitive = false;
            
            % Plot the full scope view or only the part containing
            % the main SFP
            availableViews = {...
                'full', ...
                'zoomed' ...
                };
            
            addParameter(p,'view','full',...
                 @(x) any(validatestring(x,availableViews)));
             
            p.parse(varargin{:});
            
            % This is the full spatial footprint
            sfp = obj.spatial_footprint;
            
            % See if user wants us to zoom in on the non-zero values
            if strcmpi(p.Results.view, 'zoomed')
                sfp = ml_core_remove_zero_padding(sfp);
            end
        end
        
        function [h] = plotSpatialFootprint(obj, varargin)   
            sfp = obj.getSpatialFootprint(varargin{:});
            
            h = imagesc(sfp);
            colormap jet;
        end % function
        
        function [p] = plotTraceFilt(obj)
            p = plot(obj.timestamps_ms, obj.trace_filt, 'b-');
        end % function
        
        function [p] = plotTraceRaw(obj)
            p = plot(obj.timestamps_ms, obj.trace_raw, 'k-');
        end % function
        
        function [p] = plotSpikes(obj)
            indices = find(obj.spikes > 0);
            p = stem(obj.timestamps_ms(indices), obj.spikes(indices), 'm.');
        end % function
        
        function plotTimeseries(obj)
            obj.plotTraceRaw();
            hold on
            obj.plotTraceFilt();
            obj.plotSpikes();
        end % function
    end % methods
end % classdef