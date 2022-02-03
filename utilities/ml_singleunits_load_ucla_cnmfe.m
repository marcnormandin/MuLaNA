function [data] = ml_singleunits_load_ucla_cnmfe( scopeH5Filename, neuronH5Filename, activityName )
    % This function loads the cnmfe data into the single unit structure.
    
    if ~isfile(scopeH5Filename)
        error('File (%s) does not exist.', scopeH5Filename);
    end
    
    if ~isfile(neuronH5Filename)
        error('File (%s) does not exist.', neuronH5Filename);
    end
    
    neuronDataset = ml_cai_neuron_h5_read( neuronH5Filename );
    scopeDataset = ml_cai_scope_h5_read( scopeH5Filename );
    
    data = [];

    data.numSingleUnits = neuronDataset.num_neurons;
    
    data.timeUnits = 'milliseconds';
    data.activityName = activityName;
    data.activityUnits = 'calcium_fluorescence';
    data.filterType = 'cnmfe';
    data.activityRange = 'continuous'; % continuous or discrete.
    
    timeScaleFactor = ml_util_timeunit_conversion_scalefactor( 'milliseconds', data.timeUnits );
    data.t = scopeDataset.timestamp_ms * timeScaleFactor;

    for iUnit = 1:data.numSingleUnits
        singleUnit.name = sprintf('%d', iUnit);

        singleUnit.t = [];
        singleUnit.activity = [];
        try
            
            
            
            a = neuronDataset.neuron(iUnit).(data.activityName);
            
            % Normalize by dividing by the maximum
            ma = max(a);
            a = a ./ ma;
            
            singleUnit.activity = a;
            singleUnit.isValid = true;
        catch e
            singleUnit.isValid = false;
        end
        
        data.singleUnit(iUnit) = singleUnit;
    end
end % function