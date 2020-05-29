% Example data
positionX = trial.extractedX;
positionY = trial.extractedY;
speed = zeros(1,length(positionX));
headDirection = trial.extractedAngle;
timestampsMs = trial.timeStamps_mus ./ 1000.0;

filename = 'trial_1_nvt.h5';

% Write the arrays to H5
mlbehaviour.MLBehaviourWriterH5.write(filename, positionX, positionY, speed, headDirection, timestampsMs);

% Read the arrays from H5
behav = mlbehaviour.MLBehaviourReaderH5(filename);

% Plot
figure
behav.plotPath()
set(gca, 'ydir', 'reverse')

behav.plotFigureSummary();