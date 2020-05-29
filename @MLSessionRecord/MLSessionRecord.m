classdef MLSessionRecord < handle
    % This loads a session_record.json file that contains
    % the information on all trials performed in the session
    
    properties (SetAccess = private)
        jsonFilename;
        json;
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
        
        function [name] = getName(obj)
            name = obj.json.session_info.name;
        end
        
        function [d] = getDate(obj)
            d = obj.json.session_info.date;
        end
        
        % Total number of trials, including those we dont want to process
        function [numTrials] = getNumTrials(obj)
            numTrials = length(obj.json.trial_info.sequence_num);
        end % function
        
        % This returns information for every trial regardless
        % of context or use (not filtered).
        function [trialInfo] = getTrials(obj)
            trialInfo = struct('context', [], 'use', [], 'sequenceNum', [], 'digs', [], 'id', [], 'folders', []);

            numTrials = obj.getNumTrials();
            for iTrial = 1:numTrials
                trialInfo(iTrial) = obj.getTrialInfo_single(iTrial);
            end
        end
        
        % Set a trial id not to use "drop it"
        function dropTrialId(obj, trialId)
           if trialId < 0 || trialId > obj.getNumTrials()
               error('Trial id (%d) is invalid. Cannot drop requested trial.', trialId);
           end
           
           obj.json.trial_info.use(trialId) = 0;
           
           % Renumber the sequence array
           ids = find(obj.json.trial_info.use == 1);
           for i = 1:length(ids)
               obj.json.trial_info.sequence_num(ids(i)) = i;
           end
        end % function
        
        % The number of trials we want to process (marked use = 1).
        function [numTrials] = getNumTrialsToProcess(obj)
            ti = obj.getTrialInfoAll();
            numTrials = sum([ti.use] == 1);
        end % function
        
        function [trialInfo] = getTrialsToProcess(obj)
            trialInfo = obj.getTrialInfoAll();
            use = [trialInfo.use];
            
            trialInfo(use == 0) = [];
        end % function
        
        function [trialIds] = getTrialIdsToProcess(obj)
            trialInfo = obj.getTrialsToProcess();
            trialIds = [trialInfo.id];
        end % function
        
        % Return the json array
        function [sequenceNums] = getSequenceNumsArray(obj)
            sequenceNums = obj.json.trial_info.sequence_nums;
        end % function
        
        % Return the json array
        function [contexts] = getContextsArray(obj)
            contexts = obj.json.trial_info.contexts;
        end % function
        
        % Return the json array
        function [use] = getUseArray(obj)
            use = obj.json.trial_info.use;
        end % function
        
        % Return the negation of the use array
        function [dropped] = getDroppedArray(obj)
            dropped = ~obj.json.trial_info.use;
        end % function
        
        % Return the json array
        function [digs] = getDigsArray(obj)
            digs = obj.json.trial_info.digs;
        end % function
        
        
        
        function [trialInfo] = getTrialInfoByContextId(obj, iContext)
            if iContext < 0 || iContext > obj.getNumContexts()
                error('Requested an invalid context id (%d).', iContext);
            end
            
            
            
            % Struct array to hold all matches for the requested context
            trialInfo = struct('context', [], 'use', [], 'sequenceNum', [], 'digs', [], 'id', [], 'folders', []);
            
            numTrials = obj.getNumTrials();
            for iTrial = 1:numTrials
                ti = obj.getTrialInfo(iTrial);
                if ti.context == iContext
                    trialInfo(end+1) = ti;
                end
            end
        end
        
        % How many trials were marked as to not be used
        function [numDroppedTrials] = getNumDroppedTrials(obj)
            numDroppedTrials = sum(obj.getDroppedArray());
        end % function
       
        % This returns information for every trial regardless
        % of context or use (not filtered).
        function [trialInfo] = getTrialInfoAll(obj)
            trialInfo = struct('context', [], 'use', [], 'sequenceNum', [], 'digs', [], 'id', [], 'folders', []);

            numTrials = obj.getNumTrials();
            for iTrial = 1:numTrials
                trialInfo(iTrial) = obj.getTrialInfo_single(iTrial);
            end
        end
        
        
        % Vectorized.
        % e.g. trialIds = 6, or trialIds = [1,4,5]. or nothing.
        function [trialInfo] = getTrialInfo(obj, varargin)
            % Make the input parameter optional. If no input is given
            % then assume user wants information on all of the trials
            p = inputParser;
            p.CaseSensitive = false;
            addRequired(p, 'obj');
            
            % All trials, single trial, or array of trials
            defaultTrialIds = 1:obj.getNumTrials(true); % include the dropped frames
            addOptional(p, 'trialIds', defaultTrialIds, @(x) isnumeric(x));
            
            % Include or exclude dropped trials
            useDroppedDefault = true;
            addOptional(p,'useDropped',useDroppedDefault,...
                 @(x) islogical(x));
             
            parse(p, obj, varargin{:});
            
            if isempty(p.Results.trialIds)
                trialIds = defaultTrialIds;
            else
                trialIds = p.Results.trialIds;
            end
            useDropped = p.Results.useDropped;
            
            trialInfo = struct('context', [], 'use', [], 'sequenceNum', [], 'digs', [], 'id', [], 'folders', []);

            % Get all of the data, and then filter it for what user wants
            trialInfoAll = obj.getTrialInfoAll();
            
            if length(trialIds) > 1
                % array
                for iTrial = 1:length(trialIds)
                    ti = trialInfoAll(trialIds(iTrial));
                    if ~useDropped
                        if ti.use == 0
                            % skip it
                            continue;
                        end
                    end
                       
                    % write over the first one since it is empty
                    if length(trialInfo) == 1 && isempty(trialInfo.sequenceNum)
                        trialInfo(1) = ti;
                    else
                        trialInfo(end+1) = ti;
                    end
                end
            else
                % single
                trialInfo = trialInfoAll(trialIds);
                if ~useDropped && trialInfo.use == 0
                    trialInfo = [];
                end
            end
        end
        
        
        function [trialIds] = getTrialIdsByContext(obj, iContext, varargin)
            if iContext < 0 || iContext > obj.getNumContexts()
                error('Requested an invalid context id (%d).', iContext);
            end
            
            % See if the user wants all possible contexts, or only the
            % the ones marked "use == 1"
            p = inputParser;
            p.CaseSensitive = false;
            
            addRequired(p, 'obj');
            addRequired(p, 'iContext');
            
            useDroppedDefault = true;
            
            % Include or exclude dropped trials
            addOptional(p,'useDropped',useDroppedDefault,...
                 @(x) islogical(x));
            
            parse(p, obj, iContext, varargin{:});
            
            useDropped = p.Results.useDropped;
            
            ti = obj.getTrialInfoByContextId(iContext);
            
            if useDropped
                trialIds = [ti.id];
            else
                % eliminate the dropped trials
                eliminate = [];
                for i = 1:length(ti)
                    if ti(i).use == 0
                        eliminate(end+1) = i;
                    end
                end
                trialIds = [ti.id];
                trialIds(eliminate) = [];
            end
            
            if isempty(trialIds)
                warning('No matching trials ids for context (%d).', iContext);
            end
            
        end
        
        function [numContexts] = getNumContexts(obj)
            ti = obj.getTrialInfo();
            trialContexts = [ti.context];
            numContexts = length(unique(trialContexts));
        end % function
        

        
        function [sequenceNum] = getSequenceNumByTrialId(obj, iTrial)
            ti = obj.getTrialInfo( iTrial );
            sequenceNum = ti.sequenceNum;
        end % function
        
        function [trialNum] = getTrialNumByTrialId(obj, iTrial)
            ti = obj.getTrialInfo(iTrial);
            trialNum = ti.trialNum;
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
                           error('Error. Unable to find (%s.%s) in (%s).\n', topField, subField, obj.jsonFilename);
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
            sameLengthFields = {'sequence_num', 'contexts', 'use', 'digs'};
            N = length(obj.json.trial_info.(sameLengthFields{1}));
            for iField = 2:length(sameLengthFields)
                n = length(obj.json.trial_info.(sameLengthFields{iField}));
                if n ~= N
                    error('Invalid array length (%d) for trial_info.%s', n, sameLengthFields{Field});
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
        
        % Helper function
        function [trialInfo] = getTrialInfo_single(obj, iTrial)
            if iTrial < 0 || iTrial > obj.getNumTrials()
                error('Invalid trial id (%d).', iTrial);
            end
            
            trialInfo.context = obj.json.trial_info.contexts(iTrial);
            trialInfo.use = obj.json.trial_info.use(iTrial);
            trialInfo.sequenceNum = obj.json.trial_info.sequence_num(iTrial);
            trialInfo.digs = obj.json.trial_info.digs(iTrial);
            trialInfo.id = iTrial;
            trialInfo.folders = obj.json.trial_info.folders{iTrial};
        end
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
                record.trial_info.folders = [];
            else
                if length(folders) ~= numTrials
                    error('The number of folders does not equal the number of trials.');
                end
                record.trial_info.folders = cell(numTrials, 1);
                for iTmp = 1:numTrials
                    record.trial_info.folders{iTmp} = folders{iTmp};
                end
            end

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
