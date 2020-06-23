function cnmfe_to_neuron( obj, session, trial )
    %Remove any previous results otherwise it requires user interaction
    neuronFilename = fullfile(trial.getAnalysisDirectory(), 'neuron.hdf5');
    if isfile(neuronFilename)
       delete(neuronFilename);
       if obj.isVerbose()
           fprintf('Deleted file: %s\n', neuronFilename);
       end
    end

    % Run the CNMFE
    %mlvidrecScope = MLVideoRecord([trial.analysisFolder filesep 'scope.hdf5']);

    %maxIterations = 1000;
    x = load(fullfile(trial.getAnalysisDirectory(), 'cnmfe.mat'));

    ml_cai_create_neuron_hdf5(neuronFilename, x.cnmfe.RawTraces, x.cnmfe.FiltTraces, x.cnmfe.neuron.S', x.cnmfe.SFPs);
end