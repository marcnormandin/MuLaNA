classdef MLContinuousPlacemap < handle

    properties (SetAccess = private)
        % Copies of the inputs
        x = [];
        y = [];
        ts_ms = [];
        trace_ts_ms = [];
        trace_value = [];
        
        x_input = [];
        y_input = [];
        ts_ms_input = [];
        trace_ts_ms_input = [];
        trace_value_input = [];
        
        
        trace_x = [];
        trace_y = [];
        
        % Either input or defaults
        boundsx = [];%
        boundsy = [];
        nbinsx = [];
        nbinsy = [];
        smoothingKernel = [];
        
        % Save the parameter structure
        p = [];
        
        % Discretized values
        xi = [];
        yi = [];
        sxi = [];
        syi = [];
        xedges = [];
        yedges = [];
        x_bounded = [];
        y_bounded = [];
        passedSpeedTracei = []; % These are indices into the position of trace that passed the spike thresholds
        passedTracei = [];
        passed_trace_ts_ms = [];
        passed_trace_value = [];
        passed_trace_x = [];
        passed_trace_y = [];
       

        speed_cm_per_second = [];
        
        % Two-dimensional maps
        traceMapTrue = [];
        traceMap = [];
        eventMap = [];
        
        visitedCountMap = [];
        dwellTimeMapTrue = []; % before criteria
        dwellTimeMap = []; % after criteria
        positionProbMap = [];
        
        % Smoothed two-dimensional maps
        eventMapSmoothed = [];
        traceMapSmoothed = [];
        
        dwellTimeMapSmoothed = [];
        positionProbMapSmoothed = [];
            
        % Computed values
        totalDwellTime = 0;
        isPlaceCell = false;
    end
    
    methods
        function obj = MLContinuousPlacemap(x, y, ts_ms, trace_value, trace_ts_ms, varargin)
            % Reshape
            x = reshape(x, 1, length(x));
            y = reshape(y, 1, length(y));
            ts_ms = reshape(ts_ms, 1, length(ts_ms));
            trace_value = reshape(trace_value, 1, length(trace_value));
            trace_ts_ms = reshape(trace_ts_ms, 1, length(trace_ts_ms));
            
            p = inputParser;
            p.CaseSensitive = false;
            
            checkArray = @(x) isnumeric(x);
            checkBounds = @(a) length(a) == 2 && a(1) < a(2) && isnumeric(a);
            checkPositive = @(x) length(x) == 1 && x > 0 && isnumeric(x);
            checkPositiveOrZero = @(x) length(x) == 1 && x >= 0 && isnumeric(x);
            
            % Required
            addRequired(p, 'x', checkArray);
            addRequired(p, 'y', checkArray);
            addRequired(p, 'ts_ms', checkArray);
            addRequired(p, 'trace_ts_ms', checkArray);
            addRequired(p, 'trace_value', checkArray);

            defaultKernel = fspecial('gaussian', 15, 3);
            defaultKernel = defaultKernel ./ max(defaultKernel(:));
            
            availableSmoothingProtocols = {...
                'SmoothAfterDivision', ...
                'SmoothBeforeDivision' ...
                };
            
            % Parameters
            addParameter(p,'smoothingProtocol','SmoothBeforeDivision',...
                 @(x) any(validatestring(x,availableSmoothingProtocols)));
            addParameter(p, 'speed_cm_per_second', []);
            addParameter(p, 'boundsx', [min(x), max(x)], checkBounds);
            addParameter(p, 'boundsy', [min(y), max(y)], checkBounds);
            addParameter(p, 'nbinsx', 20, checkPositive);
            addParameter(p, 'nbinsy', 30, checkPositive);
            addParameter(p, 'smoothingKernel', defaultKernel, @(x) isnumeric(x) );
            addParameter(p, 'criteriaDwellTimeSecondsPerBinMinimum', 0, checkPositiveOrZero);
            addParameter(p, 'criteria_speed_cm_per_second_minimum', 0, checkPositiveOrZero);
            addParameter(p, 'criteria_speed_cm_per_second_maximum', inf, checkPositiveOrZero);
            addParameter(p, 'criteria_trace_threshold_minimum', 0, checkPositiveOrZero);


            % Store the required inputs
            obj.x = x;
            obj.y = y;
            obj.ts_ms = ts_ms;
            obj.trace_ts_ms = trace_ts_ms;
            obj.trace_value = trace_value;
            
            obj.x_input = x;
            obj.y_input = y;
            obj.ts_ms_input = ts_ms;
            obj.trace_ts_ms_input = trace_ts_ms;
            obj.trace_value_input = trace_value; % because we may modify it
            
            % FixMe! This shouldn't be needed if the data was always good
            % Remove bad behaviour data
            badi = find(diff(obj.ts_ms) <= 0);
            badi = union(badi, badi+1);
            obj.ts_ms(badi) = [];
            obj.x(badi) = [];
            obj.y(badi) = [];
            
            % FixMe! This shouldn't be needed if the data was always good
            % Remove bad cell data
            badit = find(diff(obj.trace_ts_ms) <= 0);
            badit = union(badit, badit+1);
            obj.trace_ts_ms(badit) = [];
            obj.trace_value(badit) = [];
            
            % Process the inputs and optionals
            parse(p, x, y, ts_ms, trace_value, trace_ts_ms, varargin{:});
            
            % Store the values that will be used
            obj.boundsx = p.Results.boundsx;
            obj.boundsy = p.Results.boundsy;
            obj.nbinsx = p.Results.nbinsx;
            obj.nbinsy = p.Results.nbinsy;
            obj.smoothingKernel = p.Results.smoothingKernel;
            obj.speed_cm_per_second = p.Results.speed_cm_per_second;
            obj.trace_x = interp1( obj.ts_ms, obj.x, obj.trace_ts_ms );
            obj.trace_y = interp1( obj.ts_ms, obj.y, obj.trace_ts_ms );
            
            if ~isempty(obj.speed_cm_per_second)
                obj.speed_cm_per_second(badi) = [];
            end
            
            obj.p = p;
            
            % Check that the array behaviour lengths are the same length and that the
            % timestamps are valid.
            numPoints = length(obj.x);
            if length(obj.y) ~= numPoints || length(obj.ts_ms) ~= numPoints
                error('The arrays x, y, and ts_ms must all be the same length!');
            end
           
            
            if any(diff(obj.ts_ms) < 0)
                error('The timestamp array, ts_ms, must be monotonically increasing, but it is not!');
            end

            % Check that the array trace lengths are the same length and that the
            % timestamps are valid.
            if length(obj.trace_ts_ms) ~= length(obj.trace_value)
                error('The timestamps of values for the trace must be the same length!');
            end
            if any(diff(obj.trace_ts_ms) < 0)
                error('The timestamp array, trace_ts_ms, must be monotonically increasing, but it is not!');
            end
            
            compute(obj);
        end
        
        function compute(obj)
            % TEMP HACK
            % Computes speed if not given any
            if isempty(obj.speed_cm_per_second)
                dx = [0, diff(obj.x)];
                dy = [0, diff(obj.y)];
                dt = [0, diff(obj.ts_ms)]./1000.0;
                dtm = median(dt);
                obj.speed_cm_per_second = sqrt( dx.^2 + dy.^2 ) ./ dtm;
                obj.speed_cm_per_second = movmean(obj.speed_cm_per_second,ceil(2./dtm));
            end
            
            % We only want to use trace values that are above the speed criteria
            % threshold for inclusion in the map
            if ~isempty(obj.speed_cm_per_second)
                if length(obj.speed_cm_per_second) ~= length(obj.x)
                    error('The speed positions should be arrays of the same length')
                end
                % For each spike we see if it passes the threshold, if not,
                % we remove it
                trace_spe = interp1( obj.ts_ms, obj.speed_cm_per_second, obj.trace_ts_ms );
                
                passedSpeedi1 = find(trace_spe >= obj.p.Results.criteria_speed_cm_per_second_minimum);
                passedSpeedi2 = find(trace_spe <= obj.p.Results.criteria_speed_cm_per_second_maximum);
                
                obj.passedSpeedTracei = intersect(passedSpeedi1, passedSpeedi2);
                % The above finds the unique spike indices, but there may
                % be more than one spike per index
            else
                % No speeds given so don't limit
                obj.passedSpeedTracei = 1:length(obj.trace_ts_ms);
            end
            
%             spikey = true;
%             if spikey
%                 Now find periods where the trace is increasing
%                 dTrace = [0, diff(obj.trace_value)];
%                 increasingI = find(dTrace > 0);
% 
%                 Passed: increasing + above speed threshold
%                 obj.passedTracei = intersect(increasingI, obj.passedSpeedTracei);
% 
%                 Use only values that are larger than a minimum percentile
%                 trace_value_minium = prctile(obj.trace_value, obj.p.Results.criteria_trace_threshold_minimum);
%                 passedTraceMinimumi = find(obj.trace_value >= trace_value_minium);
% 
%                 obj.passedTracei = intersect(obj.passedTracei, passedTraceMinimumi);
%             else
%                 obj.passedTracei = obj.passedSpeedTracei;
%             end
            
            % HACKISH TO GET IT DONE FOR THE MEETING
            %dt_s = median( diff(obj.trace_ts_ms/1000.0), 'all' );
            spike_times_ms = ml_cai_estimate_spikes(obj.trace_ts_ms, obj.trace_value);
            %obj.trace_value = zeros(size(obj.trace_value));
            spikeIndices = zeros(1, length(spike_times_ms));
            for iSpike = 1:length(spike_times_ms)
               %fprintf('%d ', iSpike);
               si = find( obj.trace_ts_ms >= spike_times_ms(iSpike), 1, 'first' );
               % This shouldn't be possible, but who knows...
               if isempty(si)
                   spikeIndices(iSpike) = nan;
               else
                   spikeIndices(iSpike) = si;
               end
            end
            % Allow for more than one spike in the given time instant
            spikeIndices(isnan(spikeIndices)) = [];
%             for iSpike = 1:length(spikeIndices)
%                 obj.trace_value(spikeIndices(iSpike)) = obj.trace_value(spikeIndices(iSpike)); % + 1;
%             end
            obj.passedTracei = intersect(spikeIndices, obj.passedSpeedTracei);

            obj.passed_trace_x = obj.trace_x(obj.passedTracei);
            obj.passed_trace_y = obj.trace_y(obj.passedTracei);
            obj.passed_trace_ts_ms = obj.trace_ts_ms(obj.passedTracei);
            obj.passed_trace_value = obj.trace_value(obj.passedTracei);


            % Discretize the position data so we can bin it
            [obj.x_bounded, obj.y_bounded, obj.xi, obj.yi, obj.xedges, obj.yedges] = ...
                ml_core_compute_binned_positions(obj.x, obj.y, obj.boundsx, obj.boundsy, obj.nbinsx, obj.nbinsy);


            obj.visitedCountMap = ml_placefield_visitedcountmap( obj.xi, obj.yi, obj.nbinsx, obj.nbinsy);

            % Discretize the trace positions
            [~, ~, obj.sxi, obj.syi, ~, ~] = ...
                ml_core_compute_binned_positions(obj.passed_trace_x, obj.passed_trace_y, obj.boundsx, obj.boundsy, obj.nbinsx, obj.nbinsy);
            
            obj.traceMapTrue = ml_cai_placefield_tracemap(obj.sxi, obj.syi, obj.passed_trace_value, obj.nbinsx, obj.nbinsy);
            
            obj.traceMap = obj.traceMapTrue;
            
            obj.traceMapSmoothed = imfilter( obj.traceMap, obj.smoothingKernel);
            
            % The dwell time map before applying the criteria
            ts_s = (obj.ts_ms - obj.ts_ms(1)) ./ (1.0*10^3);
            obj.dwellTimeMapTrue = ml_placefield_dwelltimemap(obj.xi, obj.yi, ts_s, obj.nbinsx, obj.nbinsy);
            obj.totalDwellTime = sum(obj.dwellTimeMapTrue, 'all');

            % The dwell time map after applying the criteria
            obj.dwellTimeMap = obj.dwellTimeMapTrue;            
            obj.dwellTimeMapSmoothed = imfilter( obj.dwellTimeMap, obj.smoothingKernel);
            
            % Use the unsmoothed maps that passed the criteria
            obj.eventMap = ml_placefield_meanfiringratemap(obj.traceMap, obj.dwellTimeMap );
            obj.eventMap = obj.traceMap ./ obj.dwellTimeMap;
            obj.eventMap(isnan(obj.eventMap)) = 0;
            obj.eventMap(isinf(obj.eventMap)) = 0;

             % Calculate some values from the maps (use the unsmoothed maps)
            obj.positionProbMap = ml_placefield_positionprobmap( obj.dwellTimeMap );
            
            % Calculate the values using the smoothed maps
            obj.positionProbMapSmoothed = ml_placefield_positionprobmap( obj.dwellTimeMapSmoothed );
            

            % Method 1
            if strcmpi(obj.p.Results.smoothingProtocol, 'SmoothBeforeDivision')
                obj.eventMapSmoothed = obj.traceMapSmoothed ./ obj.dwellTimeMapSmoothed;
                obj.eventMapSmoothed(isnan(obj.eventMapSmoothed)) = 0;
                obj.eventMapSmoothed(isinf(obj.eventMapSmoothed)) = 0;    
            elseif strcmpi(obj.p.Results.smoothingProtocol, 'SmoothAfterDivision')
            % Method 2
                obj.eventMapSmoothed = imfilter( obj.eventMap, obj.smoothingKernel);
            else
                error('Invalid value for placemaps.smoothingProtocol (%s). Must be SmoothBeforeDivision or SmoothAfterDivision.', obj.p.Results.smoothingProtocol);
            end
        end % function
        
        function plot_path_with_spikes(obj)
            plot(obj.x, obj.y, '-', 'color', [0,0,1,0.8])

            hold on
            % These are the spikes that passed the velocity check
%             spikeScatter1 = scatter(obj.passed_trace_x, obj.passed_trace_y, 4, 'mo', 'markerfacecolor', 'm');
%             spikeScatter1.MarkerFaceAlpha = 0.6;
%             spikeScatter1.MarkerEdgeAlpha = 0.6;
            
            spikeScatter2 = scatter(obj.passed_trace_x, obj.passed_trace_y, 25, 'ro', 'markerfacecolor', 'r');
            spikeScatter2.MarkerFaceAlpha = 0.6;
            spikeScatter2.MarkerEdgeAlpha = 0.6;
            
            set(gca, 'ydir', 'reverse')
            axis equal off
        end
        
        function plot(obj)
            [nr,nc] = size(obj.eventMapSmoothed);
            
            pm = obj.eventMapSmoothed;
            %pm(obj.visitedCountMap == 0) = nan;
            pcolor( [pm, nan(nr,1); nan(1,nc+1)] ) 
            shading flat;
            set(gca, 'ydir', 'reverse');

            axis image off
            %colormap jet 
        end
        
        function plot_eventMap(obj)
            [nr,nc] = size(obj.eventMap);
            
            pm = obj.eventMap;
            pm(obj.visitedCountMap == 0) = nan;
            pcolor( [pm, nan(nr,1); nan(1,nc+1)] ) 
            shading flat;
            set(gca, 'ydir', 'reverse');

            %title(sprintf('(%0.2f, %0.2f) Hz\n(%0.2f b/s, %0.2f b)', ...
            %    obj.peakFiringRateSmoothed, obj.meanFiringRateSmoothed, obj.informationRateSmoothed, obj.informationPerSpikeSmoothed ))
            axis image off
            %colormap jet 
        end
        
        function plot_eventMapSmoothed(obj)
            [nr,nc] = size(obj.eventMapSmoothed);
            
            pm = obj.eventMapSmoothed;
            pm(obj.visitedCountMap == 0) = nan;
            pcolor( [pm, nan(nr,1); nan(1,nc+1)] ) 
            shading interp;
            set(gca, 'ydir', 'reverse');

            %title(sprintf('(%0.2f, %0.2f) Hz\n(%0.2f b/s, %0.2f b)', ...
            %    obj.peakFiringRateSmoothed, obj.meanFiringRateSmoothed, obj.informationRateSmoothed, obj.informationPerSpikeSmoothed ))
            axis image off
            %colormap jet 
        end
        
        function plot_traceMap(obj)
            [nr,nc] = size(obj.traceMap);
            
            pm = obj.traceMap;
            %pm(obj.visitedCountMap == 0) = nan;
            pcolor( [pm, nan(nr,1); nan(1,nc+1)] ) 
            shading flat;
            set(gca, 'ydir', 'reverse');

            %title(sprintf('(%0.2f, %0.2f) Hz\n(%0.2f b/s, %0.2f b)', ...
            %    obj.peakFiringRateSmoothed, obj.meanFiringRateSmoothed, obj.informationRateSmoothed, obj.informationPerSpikeSmoothed ))
            axis image off
            %colormap jet 
        end
        
        function plot_traceMapSmoothed(obj)
            [nr,nc] = size(obj.traceMapSmoothed);
            
            pm = obj.traceMapSmoothed;
            %pm(obj.visitedCountMap == 0) = nan;
            pcolor( [pm, nan(nr,1); nan(1,nc+1)] ) 
            shading flat;
            set(gca, 'ydir', 'reverse');

            %title(sprintf('(%0.2f, %0.2f) Hz\n(%0.2f b/s, %0.2f b)', ...
            %    obj.peakFiringRateSmoothed, obj.meanFiringRateSmoothed, obj.informationRateSmoothed, obj.informationPerSpikeSmoothed ))
            axis image off
            %colormap jet 
        end
        
        function plot_dwellTimeMapSmoothed(obj)
            [nr,nc] = size(obj.dwellTimeMapSmoothed);
            
            pm = obj.dwellTimeMapSmoothed;
            %pm(obj.visitedCountMap == 0) = nan;
            pcolor( [pm, nan(nr,1); nan(1,nc+1)] ) 
            shading flat;
            set(gca, 'ydir', 'reverse');

            %title(sprintf('(%0.2f, %0.2f) Hz\n(%0.2f b/s, %0.2f b)', ...
            %    obj.peakFiringRateSmoothed, obj.meanFiringRateSmoothed, obj.informationRateSmoothed, obj.informationPerSpikeSmoothed ))
            axis image off
            %colormap jet 
        end
          
        function plot_dwellTimeMap(obj)
            [nr,nc] = size(obj.dwellTimeMap);
            
            pm = obj.dwellTimeMap;
            %pm(obj.visitedCountMap == 0) = nan;
            pcolor( [pm, nan(nr,1); nan(1,nc+1)] ) 
            shading flat;
            set(gca, 'ydir', 'reverse');

            %title(sprintf('(%0.2f, %0.2f) Hz\n(%0.2f b/s, %0.2f b)', ...
            %    obj.peakFiringRateSmoothed, obj.meanFiringRateSmoothed, obj.informationRateSmoothed, obj.informationPerSpikeSmoothed ))
            axis image off
            %colormap jet 
            
        end
          

        

%         function plot_information_rate_distribution(obj)
%             if isempty(obj.informationRateSim)
%                 obj.compute_information_rate_pvalue();
%             end
%             nbins = 50;
%             histogram(obj.informationRateSim, nbins, 'normalization', 'pdf');
%             title(sprintf('p = %0.4f', obj.informationRate_pvalue))
%             hold on
%             xline(obj.informationRate, 'r', 'linewidth', 8);
%             xlabel('Information rate, IC (bits/s)')
%             grid on
%             model_x = linspace(min(obj.informationRateSim), max(obj.informationRateSim), 100);
%             model_y = normpdf(model_x, mean(obj.informationRateSim), std(obj.informationRateSim));
%             plot(model_x, model_y, 'k-', 'linewidth', 4)
%         end 
    end
end

