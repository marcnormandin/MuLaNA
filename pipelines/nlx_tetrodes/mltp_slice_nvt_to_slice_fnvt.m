function mltp_slice_nvt_to_slice_fnvt(obj, session)
            if obj.isVerbose()
                fprintf('Fixing the sliced data (if it has problems).\n');
            end
            
            % Get the sliced nvt files
            regStr = '^(slice_)\d+(_nvt.mat)$';
            nvtFilenames = ml_dir_regexp_files(session.getAnalysisDirectory(), regStr, false);
            
            for iSlice = 1:length(nvtFilenames)
                % Load the nvt data was that sliced
                sliceNvtFilename = nvtFilenames{iSlice};
                fprintf('Loading %s ... ', sliceNvtFilename);
                data = load(sliceNvtFilename);
                s = data.slice;
                fprintf('done!\n');
                
                % Load the ROI so that we can exclude points (set them to
                % zero if outside the ROI).
                troiFilename = fullfile(session.getSessionDirectory(), sprintf('slice_%d_arenaroi.mat', s.slice_id));
                if ~isfile(troiFilename)
                    error('Required file (%s) does not exist.', troiFilename);
                end
                tmp = load(troiFilename);
                xBounds = tmp.arenaroi.xVertices;
                yBounds = tmp.arenaroi.yVertices;
                inROI = inpolygon(s.extractedX, s.extractedY, xBounds, yBounds);
                outsideIndices = find(inROI == 0);
                s.extractedX(outsideIndices) = 0;
                s.extractedY(outsideIndices) = 0;
                s.extractedAngle(outsideIndices) = 0;
                
                interpX = ml_nlx_nvt_fix_extracted_array(s.extractedX);
                interpY = ml_nlx_nvt_fix_extracted_array(s.extractedY);
                interpAngle = ml_nlx_nvt_fix_extracted_array(s.extractedAngle);

                slice = [];
                slice.extractedX = interpX;
                slice.extractedY = interpY;
                slice.extractedAngle = interpAngle;

                slice.numSamples = s.numSamples;
                slice.startIndex = s.startIndex;
                slice.stopIndex = s.stopIndex;
                slice.timeStamps_mus = s.timeStamps_mus;
                slice.targets = s.targets;
                slice.points = s.points;
                slice.header = s.header;
                slice.slice_id = s.slice_id;
                slice.created = ml_util_gen_datetag();

                sliceFnvtFilename = fullfile(session.getAnalysisDirectory(), sprintf('slice_%d_fnvt.mat', s.slice_id));
                fprintf('Saving %s ... ', sliceFnvtFilename);
                save(sliceFnvtFilename, 'slice')
                fprintf('done!\n');
            end
        end % function
