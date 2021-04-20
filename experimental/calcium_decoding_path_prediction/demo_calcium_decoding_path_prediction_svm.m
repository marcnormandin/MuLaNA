close all
clear all
clc


sessionFolder = 'M:\Minimice\CMG162_CA1\analysis\chengs_task_2c\s1';

trialFolders = ml_dir_trial_folders(sessionFolder);

numTrials = length(trialFolders);

trial_stats = {}; % = zeros(1, neuronDataset.num_neurons);

iTrial = 2;

sessionTrialFolder = trialFolders{iTrial};

s = split(sessionTrialFolder, filesep);
s = s{end};
trial_id = str2double(s(7:end));
fprintf('Processing (%s)\n', sessionTrialFolder);

nfn = fullfile(sessionTrialFolder, 'neuron.hdf5');
[neuronDataset] = ml_cai_neuron_h5_read( nfn );

sfn = fullfile(sessionTrialFolder, 'scope.hdf5');
scopeDataset  = ml_cai_scope_h5_read( sfn );
scope_timestamps_ms = double(scopeDataset.timestamp_ms);

mfn = fullfile(sessionTrialFolder, 'movement.mat');
tmp = load(mfn);
movement = tmp.movement;
cm_per_bin = 2;

[t] = get_path_bin_transitions(movement, cm_per_bin);
[spike_timestamps_ms] = get_neuron_spikes(neuronDataset, scope_timestamps_ms);

%%
%T = struct2table(t);
for nid = 1:neuronDataset.num_neurons
    neuronName = sprintf('neuron_%d', nid);
    %st = spike_timestamps_ms{nid};
    v = neuronDataset.neuron(nid).trace_raw;
    rate = zeros(length(t),1);
    for iT = 1:length(t)
       t1 = t(iT).gstart_timestamps_ms;
       t2 = t(iT).gstop_timestamps_ms;
       
       inds = intersect(find(scope_timestamps_ms >= t1), find(scope_timestamps_ms <= t2));
       if ~isempty(inds)
            av = sum(v(inds), 'all');
       else
           av = nan;
       end
       t(iT).(neuronName) = av;
    end

end

%
T = struct2table(t)

%%
% Linear indices into the two positions we want
close all

b1 = 141;
b2 = 143;

% Neuron ids
for n1 = 1:neuronDataset.num_neurons
    for n2 = 1:neuronDataset.num_neurons
        %n1 = 14;
        %n2 = 32;

        B1 = get_bin_activity(T, b1, n1, n2);
        B2 = get_bin_activity(T, b2, n1, n2);

        figure('name', sprintf('(%d, %d)', n1, n2))
        subplot(1,2,1)
        plot(B1(:,1), B1(:,2), 'ro', 'markerfacecolor', 'r')
        hold on
        plot(B2(:,1), B2(:,2), 'bo', 'markerfacecolor', 'b')
        grid on
        axis equal


        X = [B1; B2];
        Y = zeros(size(X,1),1);
        Y(1:length(B1)) = 0;
        Y(length(B1)+1:end) = 1;
        N = size(X,1);

        % cvp = cvpartition(N,'Holdout',0.50);
        % 
        % idxTrain = training(cvp); % Extract training set indices
        % Xtrain = X(idxTrain,:);
        % Ytrain = Y(idxTrain);
        % Mdl = fitclinear(Xtrain',Ytrain','ObservationsIn','columns');
        % 
        % idxTest = test(cvp); % Extract test set indices
        % Xtest = X(idxTest,:);
        % labelsTest = predict(Mdl,Xtest','ObservationsIn','columns');


        %[Mdl,FitInfo] = fitclinear(X',Y', 'ObservationsIn', 'columns')
        %Mdl = fitcsvm(X,Y); %, 'crossval', 'on')
        Mdl = fitcsvm(X,Y,'Standardize', true, 'KernelFunction','linear','KernelScale','auto'); %, 'OptimizeHyperparameters','auto','HyperparameterOptimizationOptions',struct('AcquisitionFunctionName',.'expected-improvement-plus'));
        CVSVMModel = crossval(Mdl);
        classLoss = kfoldLoss(CVSVMModel)
        labels = predict(Mdl, X); %', 'ObservationsIn', 'columns')

        % X = X';
        % Y = Y';
        % Mdl = fitclinear(X,Y,'ObservationsIn','columns');
        % 
        % labels = predict(Mdl,X,'ObservationsIn','columns');

        % xp = X';
        % yp = labels;
        subplot(1,2,2)
        hold on
        xp = X;

        for i = 1:length(xp)
            if labels(i) == 0
                plot(xp(i,1), xp(i,2), 'rs')
            elseif labels(i) == 1
                plot(xp(i,1), xp(i,2), 'b^')
            else
                plot(xp(i,1), xp(i,2), 'ko')
            end
        end
        axis equal
        
        drawnow
        
        pause(1);
    end
    close all
end
    

%%





%%




    
    

