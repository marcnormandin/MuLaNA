function [recordingOpened] = ml_nlx_nvt_get_recording_datetime( nvtFilename )
    %% Get the date and time that the Neuralynx NVT recording was opened

    [Timestamps, X, Y, Angles, Targets, Points, Header] = Nlx2MatVT(nvtFilename, [1 1 1 1 1 1], 1, 1, [] );

    % The third line looks like this: 
    % {'## Time Opened (m/d/y): 3/9/2019  (h:m:s.ms) 11:43:1.468' }
    s = Header{3}; % third line
    t = split(s, ' ');

    % The split line looks like this
    %     {'##'         }
    %     {'Time'       }
    %     {'Opened'     }
    %     {'(m/d/y):'   }
    %     {'3/9/2019'   }
    %     {0×0 char     }
    %     {'(h:m:s.ms)' }
    %     {'11:43:1.468'}
    u = t{8};
    v = split(u, '.');
    w = split(v{1}, ':');

    recordingOpened.hour = str2double(w{1});
    recordingOpened.minute = str2double(w{2});
    recordingOpened.second = str2double(w{3});

    x = split(t{5}, '/');
    recordingOpened.year = str2double(x{3});
    recordingOpened.month = str2double(x{1});
    recordingOpened.day = str2double(x{2});
    
    recordingOpened.dateString = sprintf('%d-%d-%d', recordingOpened.year, recordingOpened.month, recordingOpened.day);
    recordingOpened.timeString = sprintf('%d:%d:%d', recordingOpened.hour, recordingOpened.minute, recordingOpened.second);
end % function