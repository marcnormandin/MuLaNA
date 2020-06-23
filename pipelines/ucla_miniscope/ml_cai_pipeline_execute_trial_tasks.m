function ml_cai_pipeline_execute_trial_tasks(pipeline_config_filename, experimentParentFolder, analysisParentFolder, tasks_filename, iSession, iTrial)

cfg = jsondecode(fileread(pipeline_config_filename));
tasks = jsondecode(fileread(tasks_filename));

%pipe = MLCalciumImagingPipeline(cfg, experimentParentFolder, analysisParentFolder);
pipe = MLMiniscopePipeline(cfg, experimentParentFolder, analysisParentFolder);

numTrialTasks = length(tasks.per_trial);
for iTrialTask = 1:numTrialTasks
    task = tasks.per_trial{iTrialTask};
    %pipe.executePerTrialTaskByIndex( task, iSession, iTrial );
    pipe.executeTrialTaskByIndices(task, iSession, iTrial );
end

end % function
