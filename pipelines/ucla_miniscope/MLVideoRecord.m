classdef MLVideoRecord < handle
    %MLVideoRecord A video record
    %   This class loads and saves the timestamps and associated
    %   information for a sequence of videos representing one
    %   video record.
    
    properties (SetAccess = private)
        thisFilename = '';
        datasetName = '';
        subjectName = '';
        labName = '';
        recordDate = '';
        recordTime = '';
        recordType = '';
        recordName = '';
        lastModified = -1;

        timestamp_ms = [];
        videoNum = [];
        frameNumGlobal = [];
        frameNumLocal = [];
        numFrames = -1;
        
        videoHardwareType = '';
        videoHardwareDescription = '';
        videoFilenamePrefix = '';
        videoFilenameSuffix = '';
        videoFramesPerSecond = -1;
        videoFramesPerSecondPercent = -1;
        videoWidth = -1;
        videoHeight = -1;
        videoMaxFramesPerVideo = -1;
    end
    
    properties (SetAccess = protected)
         frameQuality = [];
    end
    
    methods ( Access = public )
        function obj = MLVideoRecord( inputFilename )
            obj = loadhdf5(obj, inputFilename );
        end
        
        function obj = setframequality(obj, i, value)
           if i < 1 || i > obj.numFrames
               error('Invalid index (%d)', i);
           end
           
           obj.frameQuality(i) = value;
           obj.lastModified = now;
        end
    end
    
    methods ( Access = public )
        function plot_histfps(obj, varargin)
            defaultNumBins = 40;
            p = inputParser;
            addOptional(p, 'nbins', defaultNumBins, @isscalar);
            parse(p, varargin{:});
            numBins = p.Results.nbins;
            
            histogram(1./diff(double(obj.timestamp_ms)).*1000, numBins, 'normalization', 'probability')
            xlabel('FPS')
            ylabel('Probability')
            grid on
        end
        
        function obj = savefile(obj)
           % Update the frame quality which is the only thing that the user can change
           h5write(obj.thisFilename, '/frame_quality', uint64(obj.frameQuality));
           h5writeatt(obj.thisFilename, '/', 'last_modified', obj.lastModified);
        end
        
        function [tDup, nDup] = findduplicatetimestamps(obj)
            t = double(obj.timestamp_ms);
            u = unique(t);
            [n,bin] = histc(t, u);
            ix = find(n > 1);

            % The value that is duplicated
            tDup = u(ix);

            % The number of instances of the value
            nDup = n(ix);
        end
    end
        
    methods ( Access = private )
        function obj = loadhdf5(obj, fn )
            if ~isfile( fn )
                error('Unable to read from %s.\n', fn);
            end
            
            obj.thisFilename = fn;
            obj.lastModified = h5readatt( fn, '/', 'last_modified' );
            
            obj.datasetName = h5readatt( fn, '/', 'dataset_name');
            obj.subjectName = h5readatt( fn, '/', 'subject_name');
            obj.labName = h5readatt( fn, '/', 'lab_name');
            obj.recordName = h5readatt( fn, '/', 'record_name');
            obj.recordDate = h5readatt( fn, '/', 'record_date');
            obj.recordTime = h5readatt( fn, '/', 'record_time');
            obj.recordType = h5readatt( fn, '/', 'record_type' );

            obj.timestamp_ms = h5read( fn, '/timestamp_ms' );
            obj.videoNum = h5read( fn, '/videonum' );
            obj.frameNumGlobal = h5read( fn, '/framenum_global' );
            obj.frameNumLocal = h5read( fn, '/framenum_local' );
            
            obj.frameQuality = h5read( fn, '/frame_quality' );
            
            obj.numFrames = h5readatt( fn, '/', 'num_frames' );
            
            obj.videoWidth = h5readatt( fn, '/', 'video_width');
            obj.videoHeight = h5readatt( fn, '/', 'video_height');

            obj.videoHardwareType = h5readatt( fn, '/', 'video_hardware_type');
            obj.videoHardwareDescription = h5readatt( fn, '/', 'video_hardware_description');
            obj.videoFilenamePrefix = h5readatt( fn, '/', 'video_filename_prefix');
            obj.videoFilenameSuffix = h5readatt( fn, '/', 'video_filename_suffix');
            obj.videoFramesPerSecond = h5readatt( fn, '/', 'video_frames_per_second');
            obj.videoFramesPerSecondPercent = h5readatt( fn, '/', 'video_frames_per_second_percent');

            obj.videoMaxFramesPerVideo = h5readatt( fn, '/', 'video_max_frames_per_video');
        end
    end
end
