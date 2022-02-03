function [cellRegisteredStruct] = ml_cai_io_load_cellregisteredstruct(cellRegFolder)
    % This loads a file starting with 'cellRegistered' that is created by
    % the CellReg MATLAB code. If there is more than one such file in the
    % folder, an error is created.
    
    fileList = dir(fullfile(cellRegFolder, 'cellRegistered*.mat'));
    nFiles = length(fileList);
    if nFiles ~= 1
        error('More than one (%d) cellRegistered file found in %s.\n', nFiles, cellRegFolder);
    end
    
    fn = fullfile(fileList(1).folder, fileList(1).name);
    tmp = load(fn);
    cellRegisteredStruct = tmp.cell_registered_struct;
end % function