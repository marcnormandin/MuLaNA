function [h] = ml_sim_nlx_nvt_header(video_width, video_height)
    % This code simulates a header that is needed when saving similated data to
    % a Neuralynx NVT file.

    % The function should be passed in the timestamps and then we determine
    % the open and closed information based on those. Hopefully this works
    % for now.
    
    % Current date and time
    tDate = datestr(now,'mm/dd/yy');
    tTime = datestr(now,'hh:mm:ss');

    h = cell(22,1);

    % mynow = floor(now) + (16*3600+43*60) / (23*3600 + 59*60)

    h{1} = '######## Neuralynx Data File Header';
    h{2} = '## File Name: C:\MuzzioLab\2015-01-29_12-32-11\VT1.nvt';
    h{3} = sprintf('## Time Opened: (m/d/y): %s  At Time: %s ', tDate, tTime); %'## Time Opened: (m/d/y): 1/29/2015  At Time: 12:32:22.668 ';
    h{4} = sprintf('## Time Closed: (m/d/y): %s  At Time: %s ', tDate, tTime); %'## Time Closed: (m/d/y): 1/29/2015  At Time: 14:46:32.448 ';
    h{5} = '-CheetahRev 5.1.0';
    h{6} = '';
    h{7} = '-NLX_Base_Class_Name VT1';
    h{8} = '-RecordSize 1828';
    h{9} = '-IntensityThreshold 1 150';
    h{10} = '-RedThreshold 1 12';
    h{11} = '-GreenThreshold 1 9';
    h{12} = '-BlueThreshold 1 255';
    h{13} = '-Saturation 125';
    h{14} = '-Hue 23';
    h{15} = '-Brightness 121';
    h{16} = '-Contrast 101';
    h{17} = '-Sharpness 64';
    h{18} = '-DirectionOffset 0';
    h{19} = sprintf('-Resolution %d x %d', video_width, video_height); %'-Resolution 720 x 480';
    h{20} = '-CameraDelay 0';
    h{21} = '-EnableFieldEstimation false';
    h{22} = '-TargetDist 5';

end % function
