classdef MLCalciumPlacemap < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        spikeCountMap = [];
        visitedCountMap = [];
        dwellTimeMap = [];
        meanFiringRateMap = [];
        positionProbMap = [];
        meanFiringRate = [];
        peakFiringRate = [];
        informationRate = 0;
        informationPerSpike = 0;
        
        numSpikesTotal = 0;
        numSpikesUsed = 0;
        
        % parameters used
        p = {};
        
        x = [];
        y = [];
        xi = [];
        yi = [];
        ts_ms = [];
        ts_s = [];
        si = [];
        sxi = [];
        syi = [];
        boundsx = [];
        boundsy = [];
        nbinsx = [];
        nbinsy = [];
            
        xedges = [];
        yedges = [];
        x_bounded = [];
        y_bounded = [];
        
        hsize1 = 0;
        hsize2 = 0;
        kernBefore = [];
        kernAfter = [];
        
        % These use information from the above
        meanFiringRateMapSmoothed = [];
        spikeCountMapSmoothed = [];
        dwellTimeMapSmoothed = [];
    end
    
    methods
        function obj = MLCalciumPlacemap(x, y, ts_ms, si, boundsx, boundsy, nbinsx, nbinsy, varargin)
            p = inputParser;
            p.CaseSensitive = false;

            checkarray = @(x) isnumeric(x);
            addRequired(p, 'x', checkarray);
            addRequired(p, 'y', checkarray);
            addRequired(p, 'ts_ms', checkarray);
            addRequired(p, 'si', checkarray);
            
            checkbounds = @(a) length(a) == 2 && a(1) < a(2) && isnumeric(a);
            addRequired(p, 'boundsx', checkbounds);
            addRequired(p, 'boundsy', checkbounds);
            
            checknbins = @(x) length(x) == 1 && isnumeric(x) && x > 0;
            addRequired(p, 'nbinsx', checknbins);
            addRequired(p, 'nbinsy', checknbins);
            
            checkgaussiansigma = @(x) length(x) == 1 && isnumeric(x) && x >= 0;
            addParameter(p, 'GaussianSigmaBeforeDivision', checkgaussiansigma);
            addParameter(p, 'GaussianSigmaAfterDivision', checkgaussiansigma);

            addParameter(p, 'CriteriaDwellTimeSecondsPerBinMinimum', 1);
            addParameter(p, 'CriteriaSpeedCmPerSecondMinimum', 2);
            addParameter(p, 'CriteriaSpeedCmPerSecondMaximum', 15);
            addParameter(p, 'CriteriaSpikesPerBinMinimum', 4);
            addParameter(p, 'CriteriaInformationBitsPerSecondMinimum', 0.1);
            addParameter(p, 'CriteriaInformationBitsPerSpikeMinimum', 0.1);
            
            addParameter(p, 'verbose', false, @islogical);

            parse(p, x, y, ts_ms, si, boundsx, boundsy, nbinsx, nbinsy, varargin{:});

            % We need to make sure that the array lengths are the same,
            % except for the spikes indices array
            N = length(x);
            if N ~= length(y) || N ~= length(ts_ms)
                error('The arrays x, y, ts_ms, and si must all be the same length');
            end
            
            % We need to make sure that the timestamps are all increasing
            if any(diff(ts_ms) < 0)
                error('The timestamps array, ts_ms, must be monotonically increasing, but it is not.');
            end
            
            obj.x = x;
            obj.y = y;
            obj.ts_ms = ts_ms;
            obj.si = si;
            obj.boundsx = boundsx;
            obj.boundsy = boundsy;
            obj.nbinsx = nbinsx;
            obj.nbinsy = nbinsy;
            
            obj.numSpikesTotal = length(si);
            
            obj.p = p;
            
            % Old version before the addition of the criteria
%             [obj.x_bounded, obj.y_bounded, obj.xedges, obj.yedges, obj.xi, obj.yi, obj.sxi, obj.syi, ...
%                 obj.spikeCountMap, obj.visitedCountMap, obj.dwellTimeMap, ...
%                 obj.positionProbMap, obj.meanFiringRateMap, ...
%                 obj.dwellTimeMapSmoothed, obj.spikeCountMapSmoothed, obj.meanFiringRateMapSmoothed, ...
%                 obj.meanFiringRateMapPlot, obj.dwellTimeMapPlot, ...
%                 obj.meanFiringRateMapSmoothedPlot ] = ml_cai_placefield_compute_all(x, y, ts_ms, si, boundsx, boundsy, nbinsx, nbinsy, gaussianSigmaBeforeDivision, gaussianSigmaAfterDivision);
            obj.compute_placemap_using_criteria();
        end
        
        function compute_placemap_using_criteria(obj)
            % Convert timestamps from ms to seconds, and start at 0 seconds
            obj.ts_s = (obj.ts_ms - obj.ts_ms(1)) / 10^3;

            % hsize (size in units of the smoothing kernel)
            
            % Bin the positions to the given bounds
            [obj.x_bounded, obj.y_bounded, obj.xi, obj.yi, obj.xedges, obj.yedges] = ml_core_compute_binned_positions(obj.x, obj.y, obj.boundsx, obj.boundsy, obj.nbinsx, obj.nbinsy);

            % Recompute the spike location since we could have potentially changed
            % the subjects location when the spike occurred. 
            obj.sxi = obj.xi(obj.si);
            obj.syi = obj.yi(obj.si);

            % Compute the basic maps before we apply the inclusion criteria
            obj.spikeCountMap = ml_placefield_spikecountmap(obj.sxi, obj.syi, obj.nbinsx, obj.nbinsy);
            obj.visitedCountMap = ml_placefield_visitedcountmap(obj.xi, obj.yi, obj.nbinsx, obj.nbinsy);
            obj.dwellTimeMap = ml_placefield_dwelltimemap(obj.xi, obj.yi, obj.ts_s, obj.nbinsx, obj.nbinsy);

            % Apply the criteria for inclusion and set to zero those bins
            % that dont pass.
%             c1 = logical(obj.spikeCountMap <= obj.p.Results.CriteriaSpikesPerBinMinimum);
%             c2 = logical(obj.dwellTimeMap <= obj.p.Results.CriteriaDwellTimeSecondsPerBinMinimum);
%             ct = logical(c1 | c2);
%             obj.spikeCountMap(ct) = 0;
            %obj.visitedCountMap(ct) = 0;
            %obj.dwellTimeMap(ct) = 0;
            
            % This is the number of spikes contributing the final maps
            % because they passed the criteria for inclusion.
            % This is used for MATLAB 2019b
            % obj.numSpikesUsed = sum(obj.spikeCountMap, 'all');
            obj.numSpikesUsed = sum(sum(obj.spikeCountMap));
            
            % This depends on the dwelltime which we modified using the
            % criteria
            obj.positionProbMap = ml_placefield_positionprobmap(obj.dwellTimeMap);
            %obj.positionProbMap(ct) = 0;
            
            if mod(ceil(obj.p.Results.GaussianSigmaBeforeDivision*5),2) == 1
                obj.hsize1 = ceil(obj.p.Results.GaussianSigmaBeforeDivision*5);
            else
                obj.hsize1 = ceil(obj.p.Results.GaussianSigmaBeforeDivision*5)+1;
            end
            
            if mod(ceil(obj.p.Results.GaussianSigmaAfterDivision*5),2) == 1
                obj.hsize2 = ceil(obj.p.Results.GaussianSigmaAfterDivision*5);
            else
                obj.hsize2 = ceil(obj.p.Results.GaussianSigmaAfterDivision*5)+1;
            end
            
            if obj.p.Results.GaussianSigmaBeforeDivision ~= 0
                obj.kernBefore = fspecial('gaussian', obj.hsize1, obj.p.Results.GaussianSigmaBeforeDivision);
                obj.kernBefore = obj.kernBefore ./ max(max(obj.kernBefore(:)));
            else
                obj.kernBefore = 0;
            end
            
            if obj.p.Results.GaussianSigmaAfterDivision ~= 0
                obj.kernAfter = fspecial('gaussian', obj.hsize2, obj.p.Results.GaussianSigmaAfterDivision);
                obj.kernAfter = obj.kernAfter ./ max(max(obj.kernAfter(:)));
            else
                obj.kernAfter = 0;
            end
            
            % Compute the mean firing rate after applying the criteria
            obj.meanFiringRateMap = ml_placefield_meanfiringratemap(obj.spikeCountMap, obj.dwellTimeMap, obj.kernBefore);


            

            
            % Smooth it
            if obj.p.Results.GaussianSigmaBeforeDivision ~= 0
                %obj.dwellTimeMapSmoothed = imgaussfilt(obj.dwellTimeMap, obj.p.Results.GaussianSigmaBeforeDivision);
                obj.dwellTimeMapSmoothed = imfilter(obj.dwellTimeMap, obj.kernBefore);%, 'replicate', 'same', 'conv');
            else
                obj.dwellTimeMapSmoothed = obj.dwellTimeMap;
            end

            % Smooth it
            if obj.p.Results.GaussianSigmaBeforeDivision ~= 0
                %obj.spikeCountMapSmoothed = imgaussfilt(obj.spikeCountMap, obj.p.Results.GaussianSigmaBeforeDivision);
                obj.spikeCountMapSmoothed = imfilter(obj.spikeCountMap, obj.kernBefore);%, 'replicate', 'same', 'conv');
            else
                obj.spikeCountMapSmoothed = obj.spikeCountMap;
            end

            % Now smooth it again, but AFTER the division (supersmooth it?)
            if obj.p.Results.GaussianSigmaAfterDivision ~= 0
                %obj.meanFiringRateMapSmoothed = imgaussfilt(obj.meanFiringRateMap, obj.p.Results.GaussianSigmaAfterDivision);
                obj.meanFiringRateMapSmoothed = imfilter(obj.meanFiringRateMap, obj.kernAfter);%, 'replicate', 'same', 'conv');
            else
                obj.meanFiringRateMapSmoothed = obj.meanFiringRateMap;
            end
            
            % HERE BE DRAGONS
            % This uses the unsmoothed mean firing rate map, but this
            % should be checked
            infMeanFiringRateMap = ml_placefield_meanfiringratemap(obj.spikeCountMap, obj.dwellTimeMap, 0);
            [obj.meanFiringRate, obj.peakFiringRate] = ml_placefield_firingrate(infMeanFiringRateMap, obj.positionProbMap);
            [obj.informationRate, obj.informationPerSpike] = ml_placefield_informationcontent(obj.meanFiringRate, ...
                infMeanFiringRateMap, obj.positionProbMap);
           
        end % function
        
        
        function plot_path_with_spikes(obj)
            plot(obj.x_bounded, obj.y_bounded, '-', 'color', [0.5,0.5,0.5,0.8]) %arenaColours(iTrial))
            hold on
            spikeScatter = scatter(obj.x_bounded(obj.si), obj.y_bounded(obj.si), 10, 'ro', 'markerfacecolor', 'r');
            spikeScatter.MarkerFaceAlpha = 0.3;
            spikeScatter.MarkerEdgeAlpha = 0.3;
            set(gca, 'ydir', 'reverse')
            axis equal off
        end
        
        function plot(obj)
            [nr,nc] = size(obj.meanFiringRateMapSmoothed);
            pcolor( [obj.meanFiringRateMapSmoothed, nan(nr,1); nan(1,nc+1)] ) 
            shading interp;
            set(gca, 'ydir', 'reverse');
%             title(sprintf('(%0.2f, %0.2f) Hz | (%0.2f b/s, %0.2f b)', ...
%                 obj.peakFiringRate, obj.meanFiringRate, obj.informationRate, obj.informationPerSpike ))
            axis image off
            colormap jet 
        end

    end
end

