function [cscFiles, numCscFiles] = ml_nlx_get_csc_filenames(recordingFolder)
    files = dir( fullfile(recordingFolder, '*.ncs') );
    numCscFiles = length(files);
    
    cscFiles = [];
    for iFile = 1:numCscFiles
       cscFiles(iFile).full_filename = fullfile( files(iFile).folder, files(iFile).name ); 
       
       % Get the channel number
       s = split(files(iFile).name, '.ncs');
       s = s{1}; % CSC1
       B = regexp(s,'\d*','Match');
        for ii= 1:length(B)
          if ~isempty(B{ii})
              Num(ii,1)=str2double(B{ii}(end));
          else
              Num(ii,1)=NaN;
          end
        end

       cscFiles(iFile).channel_num = Num;
    end
end