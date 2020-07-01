function object_task_correlations(pipe)
% There are two forms of this task:
% 1) hab session containing 4 trials, and NO test session
% 2) hab session containing 4 trials, and test session containing 1 trial
% 3) 5 separate session each containing 1 trial.

    if pipe.Experiment.getNumSessions() == 1
        object_task_correlations_for_4hab_0test(pipe);
    elseif pipe.Experiment.getNumSessions() == 2
        object_task_correlations_for_4hab_1test(pipe);
    elseif pipe.Experiment.getNumSessions() == 5
        object_task_correlations_for_5sessions(pipe);
    else
        error('Error. The object task consecutive trials experiment has (%d) sessions, but requires either:\n1) hab session containing 4 trials, and test session containing 1 trial.\n2) 5 sessions each containing 1 trial\n', ...
            pipe.Experiment.getNumSessions());
    end
end % function
