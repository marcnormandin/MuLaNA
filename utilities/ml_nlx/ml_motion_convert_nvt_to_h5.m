function ml_motion_convert_nvt_to_h5( nvtFilename, outputFilename )

    motionData = ml_motion_load_nvt( nvtFilename );

    ml_motion_save_h5( motionData, outputFilename );

end % function