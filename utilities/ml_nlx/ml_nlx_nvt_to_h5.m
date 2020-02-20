close all
clear all
clc

nvtFilename = fullfile(pwd, 'VT1.nvt');
[TimeStamps, ExtractedX, ExtractedY, ExtractedAngle, Targets, Points, Header] = Nlx2MatVT(  nvtFilename, [1, 1, 1, 1, 1, 1], 1, 1, 1 );

outputFilename = 'VT1_nvt.h5';

numSamples = length(ExtractedX);

if isfile(outputFilename)
    delete(outputFilename)
end

h5create(outputFilename, '/x', [numSamples]);
h5write(outputFilename, '/x', ExtractedX);

h5create(outputFilename, '/y', [numSamples]);
h5write(outputFilename, '/y', ExtractedY);

h5create(outputFilename, '/t', [numSamples]);
h5write(outputFilename, '/t', TimeStamps);

h5create(outputFilename, '/angle', [numSamples]);
h5write(outputFilename, '/angle', ExtractedAngle);
