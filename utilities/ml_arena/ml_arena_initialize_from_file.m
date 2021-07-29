function [arena] = ml_arena_initialize_from_file(experimentDescriptionFilename, arenaRoiFilename)
    if ~isfile(experimentDescriptionFilename)
        error('File (%s) does not exist. Can not load the JSON data.', experimentDescriptionFilename);
    end
    
    if ~isfile(arenaRoiFilename)
        error('File (%s) does not exist. Can not load the ROI data.', arenaRoiFilename);
    end
    
    % Read in the experiment description and then get the arena field.
    json = ml_util_json_read(experimentDescriptionFilename);
    arenaJson = json.arena;
    
    % Read in the the ROI file
    tmp = load(arenaRoiFilename);
    
    % Now get the reference points differently based on whether or not the
    % data comes from the tetrode experiments or the ucla miniscope
    % experiments.
    if isfield(tmp, 'arenaroi') % tetrode
        refP = reshape(tmp.arenaroi.xVertices, 1, 4);
        refQ = reshape(tmp.arenaroi.yVertices, 1, 4);
    elseif isfield(tmp, 'behavcam_roi') % ucla miniscope
        refP = reshape(tmp.behavcam_roi.inside.j, 1, 4);
        refQ = reshape(tmp.behavcam_roi.inside.i, 1, 4);
    else
        error("ROI file (%s) should contain either 'arenaroi' or 'behavcam_roi'.", arenaRoiFilename);
    end
           
    arena = ml_arena_initialize(arenaJson, refP, refQ);
end
