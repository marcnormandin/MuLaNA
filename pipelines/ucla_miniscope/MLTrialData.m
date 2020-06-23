classdef MLTrialData
    %MLTrialData Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        dataFolder
        roi
        mlvidrecBehav
        mlvidrecScope
        track
        spatialFootprint
        ms
        cnmfe
        adjustReferenceFrame
    end
    
    methods
        function obj = MLTrialData( dataFolder )
            obj.dataFolder = dataFolder;
            x = load( fullfile(dataFolder, 'behavcam_roi.mat') );
            obj.roi = x.behavcam_roi;
            obj.mlvidrecBehav = MLVideoRecord( fullfile(dataFolder, 'behav.hdf5') );
            obj.mlvidrecScope = MLVideoRecord( fullfile(dataFolder, 'scope.hdf5') );
            obj.track = MLBehaviourTrack( fullfile(dataFolder, 'behav_track_vid.hdf5'));
            
            fn = fullfile(dataFolder, 'SFP.mat');
            if isfile(fn)
                x = load(fn);
                obj.spatialFootprint = x.SFP;
            end
            
            fn = fullfile(dataFolder, 'ms.mat');
            if isfile(fn)
                x = load(fn);
                obj.ms = x.ms;
            end
            
            fn = fullfile(dataFolder, 'cnmfe.mat');
            if isfile(fn)
                x = load(fn);
                obj.cnmfe = x.cnmfe;
            end
            
            obj.adjustReferenceFrame = false;
        end
        
        function plot_roi_reference_frame(obj, ax)
            if obj.adjustReferenceFrame
                imshow( imadjust(rgb2gray( obj.roi.refFrame )), 'Parent', ax )
            else
                imshow( obj.roi.refFrame, 'Parent', ax )
            end
        end
        
        function plot_roi(obj, ax)
            plot_roi_walls(obj, ax);
            plot_roi_other(obj, ax);
        end
        
        function plot_roi_walls(obj, ax)
            plot_roi_walls_inside(obj, ax);
            plot_roi_walls_outside(obj, ax);
        end
        
        function plot_roi_walls_inside(obj, ax)
            tf = ishold(ax);
            roi = obj.roi;
            
            plot([roi.inside.j; roi.inside.j(1)], [roi.inside.i; roi.inside.i(1)], 'b-', 'linewidth', 2, 'Parent', ax )
            hold(ax, 'on')
            
            plot(roi.inside.j, roi.inside.i, 'ko', 'markerfacecolor', 'y', 'markersize', 5, 'Parent', ax )

            hold(ax, 'off')
            if tf == false
                hold(ax, 'off')
            else
                hold(ax, 'on')
            end
        end
        
        function plot_roi_walls_outside(obj, ax)
            tf = ishold(ax);
            roi = obj.roi;
            
            plot([roi.outside.j; roi.outside.j(1)], [roi.outside.i; roi.outside.i(1)], 'r-', 'linewidth', 2, 'Parent', ax )
            hold(ax, 'on')
            plot(roi.outside.j, roi.outside.i, 'ko', 'markerfacecolor', 'y', 'markersize', 5, 'Parent', ax )
            hold(ax, 'off')
            
            if tf == false
                hold(ax, 'off')
            else
                hold(ax, 'on')
            end
        end
        
        function plot_roi_other(obj, ax)
            tf = ishold(ax);
            roi = obj.roi;
            plot(roi.other.j, roi.other.i, 'bo', 'markersize', 10, 'markerfacecolor', 'b', 'Parent', ax )
            hold(ax, 'on')
            plot(roi.other.j, roi.other.i, 'bo', 'markersize', 10, 'Parent', ax )
            hold(ax, 'off')
            if tf == false
                hold(ax, 'off')
            else
                hold(ax, 'on')
            end
        end
        
    end
end

