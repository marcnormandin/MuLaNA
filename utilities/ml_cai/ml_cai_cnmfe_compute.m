function [cnmfe, p] = ml_cai_cnmfe_compute( cnmfeOptions, alignedScopeFilenameFull, varargin )

    p = inputParser;
    p.CaseSensitive = false;
    
    addRequired(p,'cnmfeOptions', @isstruct);
    addRequired(p,'alignedScopeFilenameFull', @isstr);
    addParameter(p,'verbose', false, @islogical);    
    
    parse(p, cnmfeOptions, alignedScopeFilenameFull, varargin{:});
    
    if p.Results.verbose
        fprintf('Using the following settings:\n');
        disp(p.Results)
    end

    % Perform the calculation
    startTic = tic;
    if p.Results.verbose
        fprintf('Running CNMF-e, which will take a long time. Get a coffee!\n');
    end
    
    %alignedScopeFilenameFull = fullfile( dataFolder, p.Results.alignedScopeFilename );
    cnmfe = men_cnmfe_run( cnmfeOptions, alignedScopeFilenameFull );
    cnmfe.computationTimeMins = toc(startTic)/60;
  
    if p.Results.verbose
        fprintf('done!\n');
    end
    
end % function
