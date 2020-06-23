classdef DAQSettingsAndNotes < handle
    properties (SetAccess = private)
        animal;
        excitation;
        msCamExposure;
        recordLength;
        
        elapsedTime;
        note;
    end % properties
    
    methods
        function obj = DAQSettingsAndNotes( filename )
            if nargin ~= 1
                error('Filename required.')
            end
            
            obj = readFile( obj, filename );
        end
        
        function obj = readFile ( obj, filename )
            if ~isfile(filename)
                error('File (%s) does not exist. It can not be opened.\n', filename);
            end
            
            % open the file
            fid = fopen( filename );
            if fid == -1
                error('Unable to open the settings_and_notes file (%s).\n', filename)
            end

            % read the header and make sure that it is valid
            headerLine = fgetl(fid); % dummy read
            if headerLine == -1
                error('Invalid file.')
            end
            s = split(headerLine);
            if length(s) ~= 4
                error('Invalid file format.');
            end
            if ~strcmp(s{1}, 'animal') || ~strcmp(s{2}, 'excitation') || ~strcmp(s{3}, 'msCamExposure') || ~strcmp(s{4}, 'recordLength')
                error('Invalid file format.');
            end

            % read the animal name, excitation, etc
            l = fgetl(fid);
            s = split(l);
            if length(s) ~= 4
                error('Invalid file format')
            end
            obj.animal = s{1};
            obj.excitation = str2double(s{2});
            obj.msCamExposure = str2double(s{3});
            obj.recordLength = str2double(s{4});

            % read the blank line
            l = fgetl(fid);
            if ~isempty(l)
                error('Invalid file format')
            end

            % read the second header
            l = fgetl(fid);
            s = split(l);
            if length(s) ~= 2
                error('Invalid file format')
            end
            if ~strcmp(s{1}, 'elapsedTime') || ~strcmp(s{2}, 'Note')
                error('Invalid file format')
            end

            obj.elapsedTime = [];
            obj.note = {};

            noteNum = 0;
            while 1
                l = fgetl(fid);
                if ~ischar(l)
                    break
                end
                s = split(l);
                if length(s) < 2
                    error('Invalid file format')
                end
                noteNum = noteNum + 1;
                obj.elapsedTime = [obj.elapsedTime; str2double(s{1})];
                p = [];
                for j = 2:length(s)
                    if j == 2
                        p = s{j};
                    else
                        p = [p ' ' s{j}];
                    end
                end
                obj.note{noteNum} = p;
            end

            fclose(fid);
        end
        
    end % methods
end % classdef
