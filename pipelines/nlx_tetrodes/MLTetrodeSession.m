classdef MLTetrodeSession < MLSession
    %MLTetrodeSession A tetrode session
    %   A session specific for tetrodes
    
    properties
        TFilesFilenamePrefixes
    end
    
    methods
        function obj = MLTetrodeSession(...
                config, ...
                sessionRecord, ...
                name, date, trials, ...
                sessionDirectory, analysisDirectory)
            obj@MLSession(config, sessionRecord, name, date, trials, sessionDirectory, analysisDirectory);
            
            % init
            obj.initialize();
        end
        
        function [fn] = getTFilesFilenamePrefixes(obj)
            fn = obj.TFilesFilenamePrefixes;
        end
        
        function [n] = getNumTFiles(obj)
            n = length(obj.getTFilesFilenamePrefixes());
        end
        
        function updateListOfTFiles(obj)
            obj.TFilesFilenamePrefixes = {};
            
            % Get the list of t-files
            fl = dir(fullfile(obj.getSessionDirectory(), sprintf('TT*.t')));
            
            % Remove the extension ".t"
            for iFile = 1:length(fl)
                [filepath, name, ext] = fileparts(fl(iFile).name);
                obj.TFilesFilenamePrefixes{end+1} = name;
            end
            
            % Sort them (hackish)
            % Remove the TT
            tmp2 = [];
            for i = 1:length(obj.TFilesFilenamePrefixes)
                tmp1 = obj.TFilesFilenamePrefixes{i};
                s = tmp1(3:end); % strip the TT
                s = split(s,'_');
                % Now convert to a number
                num = str2double(s{1}) * 10 + str2double(s{2});
                tmp2(end+1) = num;
            end
            % now sort them numerically
            [sortedValue, prevIndex] = sort(tmp2);
            tFilesToUse = {};
            for i = 1:length(tmp2)
                tFilesToUse{i} = obj.TFilesFilenamePrefixes{prevIndex(i)};
            end
            
            % Store the now sorted list
            obj.TFilesFilenamePrefixes = tFilesToUse;
        end % function
        
    end
    
    methods(Access = protected)
        function obj = initialize(obj)
            obj.updateListOfTFiles();
        end
        
        
    end % methods protected
end

