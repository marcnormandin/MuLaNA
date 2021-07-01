classdef MLSessionRecord < handle
    % This loads a session_record.json file that contains
    % the information on all trials performed in the session
    
    properties (SetAccess = private)
        jsonFilename;
        json;
        
        defaultStructStr = "struct('context', [], 'use', [], 'digs', [], 'sliceId', [], 'trialId', [], 'folders', [])";
    end % properties
    
    methods (Access = public)
        function obj = MLSessionRecord( filename )
            % Store the filename so that we can update the file
            % if needed
            obj.jsonFilename = filename;
            
            obj.loadFile(obj.jsonFilename);
            
        end % function
        
        function saveFile(obj)
            ml_util_json_save(obj.json, obj.jsonFilename);
        end % function
        
        %% Raw data access
        function [name] = getName(obj)
            name = obj.json.session_info.name;
        end
        
        function [d] = getDate(obj)
            d = obj.json.session_info.date;
        end
        
        % Return the json array
        function [sequenceNums] = getRawSequenceNumsArray(obj)
            sequenceNums = obj.json.trial_info.sequence_nums;
        end % function
        
        % Return the json array
        function [contexts] = getRawContextsArray(obj)
            contexts = obj.json.trial_info.contexts;
        end % function
        
        % Return the json array
        function [use] = getRawUseArray(obj)
            use = obj.json.trial_info.use;
        end % function
        
        % Return the negation of the use array
        function [dropped] = getDroppedArray(obj)
            dropped = ~getRawUseArray(obj);
        end % function
        
        % How many trials were marked as to not be used
        function [numDroppedTrials] = getNumDroppedTrials(obj)
            numDroppedTrials = sum(obj.getDroppedArray());
        end % function
        
        % Return the json array
        function [digs] = getDigsArray(obj)
            digs = obj.json.trial_info.digs;
        end % function
        
        
        
        %% The basic unit is a slice.
        
        % Total number of slices, including those we dont want to process
        function [numSlices] = getNumSlices(obj)
            numSlices = length(obj.json.trial_info.sequence_num); % or length of any of the arrays
        end % function
       
        % Helper function
        function [sliceInfo] = getSliceInfo(obj, iSlice)
            if iSlice < 0 || iSlice > obj.getNumSlices()
                error('Invalid slice id (%d).', iSlice);
            end
            
            sliceInfo.context = obj.json.trial_info.contexts(iSlice);
            sliceInfo.use = obj.json.trial_info.use(iSlice);
            sliceInfo.trialId = obj.json.trial_info.sequence_num(iSlice);
            sliceInfo.digs = obj.json.trial_info.digs(iSlice);
            sliceInfo.sliceId = iSlice;
            sliceInfo.folders = obj.json.trial_info.folders{iSlice};
        end
        
        % This returns information for every slice (not filtered)
        function [slicesInfo] = getSlicesInfo(obj)
            slicesInfo = eval(obj.defaultStructStr);

            numSlices = obj.getNumSlices();
            for iSlice = 1:numSlices
                slicesInfo(iSlice) = obj.getSliceInfo(iSlice);
            end
        end
        
        
        %% Most of the analyses work on trials, which are slices
        %  that have "use == true'.
                
        % The number of trials we want to process are slices
        % that are marked as "use = true".
        function [numTrials] = getNumTrials(obj)
            sia = obj.getSlicesInfo();
            numTrials = sum([sia.use] == 1);
        end % function
        
        % Returns array of a single trial
        function [trial] = getTrialInfo(obj, trialId)
            trialsInfo = getTrialsInfo(obj);
            
            trialIds = [trialsInfo.trialId];
            ind = find(trialIds == trialId);
            trial = [];
            if length(ind) ~= 1
                warning('Trial ID %d can not be found.', trialId);
            else
                trial = trialsInfo(ind);
                
                if trial.trialId ~= trialId
                    error('Logic error');
                end
            end
        end
        
        % Returns array of all trials
        function [trialsInfo] = getTrialsInfo(obj)
            trialsInfo = getSlicesInfo(obj);
            use = [trialsInfo.use];
            trialsInfo(use == 0) = [];
        end
        
        % Get the trial ids
        function [trialIds] = getTrialIds(obj)
            trialsInfo = getTrialsInfo(obj);
            trialIds = [trialsInfo.trialId];
        end
        
        % Get the number of unique contexts used for trials
        function [numContexts] = getNumContexts(obj)
            ti = obj.getTrialsInfo();
            trialContexts = [ti.context];
            numContexts = length(unique(trialContexts));
        end % function
        
        % Get the slice id associated with a given trial id
        % or returns empty if not found.
        function [sliceId] = getSliceIdByTrialId(obj, trialId)
            ti = obj.getTrialInfo( trialId );
            sliceId = [];
            if ~isempty(ti)
               sliceId = ti.sliceId; 
            end
        end % function

    end % methods
    
    methods (Access = private)
        function loadFile(obj, filename)
            % Read the data into the json structure
            obj.readJSON(filename);
            
            % Make sure that the data makes sense logically
            % i.e. same number of array elements
            obj.validateJSON();
        end % function 
        
        function readJSON(obj, filename)            
            % Read record file
            if ~isfile( filename )
                error('The session record (%s) does not exist.', filename);
            end
            try 
                obj.json = jsondecode( fileread(filename) );
            catch ME
                error('Error encountered while reading session record from (%s): %s', filename, ME.identifier)
            end
        end % function
        
        function validateJSON(obj)
            % Make sure that the json has the required fields
            reqFields = {{'session_info', {'name', 'date'}}, ...
                {'trial_info', {'sequence_num', 'contexts', 'use', 'digs', 'folders'}}};
            for iRequired = 1:length(reqFields)
               row = reqFields{iRequired};
               topField = row{1};
               if isfield(obj.json, topField)
                   subFields = row{2};
                   for iSub = 1:length(subFields)
                       subField = subFields{iSub};
                       if ~isfield(obj.json.(topField), subField)
                           if strcmp(subField, 'folders')
                               fprintf('Warning. Unable to find (%s.%s) in (%s). This is fine for tetrode data.\n', topField, subField, obj.jsonFilename);
                               % Add empty ones
                                N = length(obj.json.trial_info.sequence_num);
                                for iAdd = 1:N
                                    obj.json.trial_info.folders{iAdd} = "";
                                end
                           else
                                error('Error. Unable to find (%s.%s) in (%s).\n', topField, subField, obj.jsonFilename);
                           end
                       end
                   end
               else
                   error('Can not find the top field (%s)', topField)
               end
            end
            
            if ~isnumeric(obj.json.trial_info.sequence_num)
                error('The array trial_info.sequence_num should be numeric.');
            end
            
            if ~isnumeric(obj.json.trial_info.use)
                error('The array trial_info.use should be numeric.');
            end

            if ~isnumeric(obj.json.trial_info.contexts)
                error('The array trial_info.contexts should be numeric.');
            end
            
            
            % Validate the arrays. Should all be the same length.
            sameLengthFields = {'sequence_num', 'contexts', 'use', 'digs', 'folders'};
            N = length(obj.json.trial_info.(sameLengthFields{1}));
            for iField = 2:length(sameLengthFields)
                n = length(obj.json.trial_info.(sameLengthFields{iField}));
                if n ~= N
                    error('Invalid array length (%d) for trial_info.%s in %s', n, sameLengthFields{iField}, obj.jsonFilename);
                end
            end
            
            % validate sequence num
            if any(obj.json.trial_info.sequence_num <= 0)
                error('Invalid value for trial_info.sequence_num. Must be >= 1.')
            end
            
            % validate 'use' values
            for i = 1:N
                if obj.json.trial_info.use(i) ~= 0 && obj.json.trial_info.use(i) ~= 1
                    error('Invalid value (%d) for trial_info.use[%d]', obj.json.trial_info.use(i));
                end
            end
            
            % Make sure that each sequence_num is unique if used
            i = find(obj.json.trial_info.use == 1);
            if length(unique(obj.json.trial_info.sequence_num(i))) ~= length(i)
                error('All used sequence nums, associated with use = 1, must be unique.');
            end
            

            
        end % function
        

    end % private methods
    
    methods ( Static )
        function createDefaultFile(numTrials, numAlternatingContexts, sessionName, sessionDate, outputFilename, folders)
            %fprintf('Creating default record.json for %s\n', outputFilename);

            record.session_info.name = sessionName;
            record.session_info.date = sessionDate;
            
            record.trial_info = struct('contexts', [], 'use', [], 'sequence_num', [], 'digs', [], 'folders', []);

            tmp = repmat(1:numAlternatingContexts, 1, ceil(numTrials/numAlternatingContexts));
            record.trial_info.contexts = tmp(1:numTrials);
            
            record.trial_info.sequence_num = 1:numTrials;
            record.trial_info.use = ones(1,numTrials);
            record.trial_info.digs = cell(1,numTrials);
            for iTmp = 1:numTrials
                record.trial_info.digs{iTmp} = "?";
            end
            
            if isempty(folders)
                folders = cell(numTrials,1);
                for iTmp = 1:numTrials
                    folders{iTmp} = "";
                end
            end
            
            if length(folders) ~= numTrials
                error('The number of folders does not equal the number of trials.');
            end
            record.trial_info.folders = cell(numTrials, 1);
            for iTmp = 1:numTrials
                record.trial_info.folders{iTmp} = folders{iTmp};
            end
%             end

            txt = jsonencode(record);
            fid = fopen(outputFilename,'w');
            if fid == -1
                error('Unable to create default record.json file.\n');
            end
            fwrite(fid, txt, 'char');
            fclose(fid);
            %fprintf('Default MLSessionRecord saved to: %s\n', outputFilename);
        end % function
    end % static methods
    
end % classdef
