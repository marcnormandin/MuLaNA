classdef MLSpikePlacemap < handle

    properties
        % Copies of the inputs
        x = [];
        y = [];
        ts_ms = [];
        si = [];
        
        % Either input or defaults
        boundsx = [];
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
        passedSpeedSpikei = []; % These are indices into the position of spikes that passed the spike thresholds
        speed_cm_per_second = [];
        
        % Two-dimensional maps
        spikeCountMapTrue = []; % before criteria
        spikeCountMap = []; % after criteria
        visitedCountMap = [];
        dwellTimeMapTrue = []; % before criteria
        dwellTimeMap = []; % after criteria
        meanFiringRateMap = [];
        positionProbMap = [];
        meanFiringRate = [];
        peakFiringRate = [];
        
        % Smoothed two-dimensional maps
        spikeCountMapSmoothed = [];
        meanFiringRateMapSmoothed = [];
        dwellTimeMapSmoothed = [];
        
        % Computed values
        informationRate = 0;
        informationPerSpike = 0;
        totalSpikes = 0;
        totalDwellTime = 0;
        isPlaceCell = false;
    end
    
    methods
        function obj = MLSpikePlacemap(x, y, ts_ms, si, varargin)
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
            addRequired(p, 'si', checkArray);
     
            % Parameters
            addParameter(p, 'smoothingProtocol', 'SmoothBeforeDivision');
            addParameter(p, 'speed_cm_per_second', []);
            addParameter(p, 'boundsx', [min(x), max(x)], checkBounds);
            addParameter(p, 'boundsy', [min(y), max(y)], checkBounds);
            addParameter(p, 'nbinsx', 20, checkPositive);
            addParameter(p, 'nbinsy', 30, checkPositive);
            addParameter(p, 'smoothingKernel', fspecial('gaussian', 9, 1.5), @(x) isnumeric(x) );
            addParameter(p, 'criteriaDwellTimeSecondsPerBinMinimum', 0, checkPositiveOrZero);
            addParameter(p, 'criteriaSpikesPerBinMinimum', 0, checkPositiveOrZero);
            addParameter(p, 'criteria_speed_cm_per_second_minimum', 0, checkPositiveOrZero);
            addParameter(p, 'criteria_speed_cm_per_second_maximum', inf, checkPositiveOrZero);

            % Store the required inputs
            obj.x = x;
            obj.y = y;
            obj.ts_ms = ts_ms;
            obj.si = si;
            
            % Process the inputs and optionals
            parse(p, x, y, ts_ms, si, varargin{:});
            
            % Store the values that will be used
            obj.boundsx = p.Results.boundsx;
            obj.boundsy = p.Results.boundsy;
            obj.nbinsx = p.Results.nbinsx;
            obj.nbinsy = p.Results.nbinsy;
            obj.smoothingKernel = p.Results.smoothingKernel;
            obj.speed_cm_per_second = p.Results.speed_cm_per_second;
            
            obj.p = p;
            
            % Check that the array lengths are the same length and that the
            % timestamps are valid.
            numPoints = length(obj.x);
            if length(obj.y) ~= numPoints || length(obj.ts_ms) ~= numPoints
                error('The arrays x, y, and ts_ms must all be the same length!');
            end
            if any(diff(obj.ts_ms) < 0)
                error('The timestamp array, ts_ms, must be monotonically increasing, but it is not!');
            end

            compute(obj);
        end
        
        function compute(obj)
            % We only want to use spikes that are above the speed criteria
            % threshold for inclusion in the map
            if ~isempty(obj.speed_cm_per_second)
                if length(obj.speed_cm_per_second) ~= length(obj.x)
                    error('The speed positions should be arrays of the same length')
                end
                % For each spike we see if it passes the threshold, if not,
                % we remove it
                passedSpeedi1 = find(obj.speed_cm_per_second >= obj.p.Results.criteria_speed_cm_per_second_minimum);
                passedSpeedi2 = find(obj.speed_cm_per_second <= obj.p.Results.criteria_speed_cm_per_second_maximum);
                
                obj.passedSpeedSpikei = obj.si(ismember(obj.si, intersect(passedSpeedi1, passedSpeedi2)));
                % The above finds the unique spike indices, but there may
                % be more than one spike per index
            else
                obj.passedSpeedSpikei = obj.si;
            end
            
            fprintf('%d spikes have been excluded using the speed criteria.\n', length(obj.si) - length(obj.passedSpeedSpikei));
            fprintf('%d spikes have passed the speed criteria.\n', length(obj.passedSpeedSpikei));

            [obj.x_bounded, obj.y_bounded, obj.xi, obj.yi, obj.xedges, obj.yedges] = ...
                ml_core_compute_binned_positions(obj.x, obj.y, obj.boundsx, obj.boundsy, obj.nbinsx, obj.nbinsy);

            % Recompute the spike location since we could have potentially changed
            % the subjects location when the spike occurred. 
            obj.sxi = obj.xi( obj.passedSpeedSpikei );
            obj.syi = obj.yi( obj.passedSpeedSpikei );

            obj.visitedCountMap = ml_placefield_visitedcountmap( obj.xi, obj.yi, obj.nbinsx, obj.nbinsy);

            % The spike count map before applying the criteria
            obj.spikeCountMapTrue = ml_placefield_spikecountmap( obj.sxi, obj.syi, obj.nbinsx, obj.nbinsy);
            
            % The spike count map after applying the criteria
            obj.spikeCountMap = obj.spikeCountMapTrue;
            obj.spikeCountMap(obj.spikeCountMap < obj.p.Results.criteriaSpikesPerBinMinimum) = 0;
            
            obj.spikeCountMapSmoothed = imfilter( obj.spikeCountMap, obj.smoothingKernel );
            
            % The dwell time map before applying the criteria
            ts_s = (obj.ts_ms - obj.ts_ms(1)) ./ (1.0*10^3);
            obj.dwellTimeMapTrue = ml_placefield_dwelltimemap(obj.xi, obj.yi, ts_s, obj.nbinsx, obj.nbinsy);

            % The dwell time map after applying the criteria
            obj.dwellTimeMap = obj.dwellTimeMapTrue;
            obj.dwellTimeMap( obj.dwellTimeMap < obj.p.Results.criteriaDwellTimeSecondsPerBinMinimum ) = 0;
            
            obj.dwellTimeMapSmoothed = imfilter( obj.dwellTimeMap, obj.smoothingKernel );
            
            
            % Use the unsmoothed maps that passed the criteria
            obj.meanFiringRateMap = ml_placefield_meanfiringratemap(obj.spikeCountMap, obj.dwellTimeMap );

            % Method 1
            if strcmpi(obj.p.Results.smoothingProtocol, 'SmoothBeforeDivision')
                obj.meanFiringRateMapSmoothed = ml_placefield_meanfiringratemap( obj.spikeCountMapSmoothed, obj.dwellTimeMapSmoothed );
            elseif strcmpi(obj.p.Results.smoothingProtocol, 'SmoothAfterDivision')
            % Method 2
                obj.meanFiringRateMapSmoothed = imfilter( ml_placefield_meanfiringratemap( obj.spikeCountMap, obj.dwellTimeMap ), obj.smoothingKernel );
            else
                error('Invalid value for placemaps.smoothingProtocol (%s). Must be SmoothBeforeDivision or SmoothAfterDivision.', obj.p.Results.smoothingProtocol);
            end
            
            % Calculate some values from the maps (use the unsmoothed maps)
            obj.positionProbMap = ml_placefield_positionprobmap( obj.dwellTimeMap );
            [obj.meanFiringRate, obj.peakFiringRate] = ml_placefield_firingrate( obj.meanFiringRateMap, obj.positionProbMap );
            [obj.informationRate, obj.informationPerSpike] = ml_placefield_informationcontent( obj.meanFiringRate, obj.meanFiringRateMap, obj.positionProbMap );

    
            obj.totalSpikes = sum(obj.spikeCountMap, 'all');
            obj.totalDwellTime = sum(obj.dwellTimeMap, 'all');
            
            if obj.meanFiringRate > 0.1 && obj.meanFiringRate < 5.0 && obj.informationRate > 0.5
                obj.isPlaceCell = true;
            end
        end % function
        
        
        function plot_path_with_spikes(obj)
            plot(obj.x_bounded, obj.y_bounded, '-', 'color', [0,0,1,0.8]) %arenaColours(iTrial))
            hold on
            % These are the spikes that passed the velocity check
            spikeScatter1 = scatter(obj.x_bounded(obj.passedSpeedSpikei), obj.y_bounded(obj.passedSpeedSpikei), 10, 'ro', 'markerfacecolor', 'r');
            spikeScatter1.MarkerFaceAlpha = 0.6;
            spikeScatter1.MarkerEdgeAlpha = 0.6;
            
%             hold on
            
            % These are the all of the spikes
%             spikeScatter2 = scatter(obj.x_bounded(obj.si), obj.y_bounded(obj.si), 10, 'ko', 'markerfacecolor', 'k');
%             spikeScatter2.MarkerFaceAlpha = 0.6;
%             spikeScatter2.MarkerEdgeAlpha = 0.6;
            set(gca, 'ydir', 'reverse')
            axis equal off
        end
        
        function plot(obj)
            [nr,nc] = size(obj.meanFiringRateMapSmoothed);
            pcolor( [obj.meanFiringRateMapSmoothed, nan(nr,1); nan(1,nc+1)] ) 
            shading interp;
            set(gca, 'ydir', 'reverse');

            title(sprintf('(%0.2f, %0.2f) Hz | (%0.2f b/s, %0.2f b)', ...
                obj.peakFiringRate, obj.meanFiringRate, obj.informationRate, obj.informationPerSpike ))
            axis image off
            colormap jet 
        end

    end
end

