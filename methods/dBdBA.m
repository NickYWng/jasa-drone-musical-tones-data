%%
clear;
close all;
clc;

%% ========================= USER SETTINGS ===============================

pRef = 20e-6;                 % reference sound pressure, Pa
analysisTimeRange = [0, 15];  % use original timestamps from 2 to 12 s
frameDuration = 0.1;          % time-varying SPL frame length, s
overlapFraction = 0.50;       % 50% overlap

datasets = struct( ...
    'name', {'drone10802', 'drone20814', 'violin0804'}, ...
    'label', {'Drone 1', 'Drone 2', 'Violin'}, ...
    'conditions', { ...
        {'3428', '4455', '5816', '7119', '8397', ...
         '9504', '10554', '11476', '12547'}, ...
        {'2125', '3456', '4541', '5424', '6387', ...
         '7213', '8467', '9423', '10377'}, ...
        {'E3', 'Gsharp3', 'B3', 'C4', 'Csharp4'}}, ...
    'repetitions', { ...
        {'rpm01', 'rpm02', 'rpm03'}, ...
        {'rpm01', 'rpm02', 'rpm03'}, ...
        {'01', '02', '03'}});

%% ========================= CALCULATE ===================================

totalSamples = sum(arrayfun(@(x) ...
    numel(x.conditions) * numel(x.repetitions), datasets));

emptyResult = struct( ...
    'Category', '', ...
    'Dataset', '', ...
    'Condition', '', ...
    'Repetition', '', ...
    'Sample', '', ...
    'File', '', ...
    'fs', NaN, ...
    'AnalysisTimeRange_s', analysisTimeRange, ...
    'FrameTime_s', [], ...
    'FrameLZ_dB', [], ...
    'FrameLA_dBA', [], ...
    'FrameDifference_ZminusA_dB', [], ...
    'OverallLZ_dB', NaN, ...
    'OverallLA_dBA', NaN, ...
    'Difference_ZminusA_dB', NaN);
results = repmat(emptyResult, totalSamples, 1);

resultIndex = 0;

for datasetIndex = 1:numel(datasets)

    dataset = datasets(datasetIndex);
    inputRoot = fullfile('recordings', dataset.name, '75A_mat');

    fprintf('\n===============================================================\n');
    fprintf('PROCESSING %s (%s)\n', upper(dataset.label), dataset.name);
    fprintf('===============================================================\n');

    for conditionIndex = 1:numel(dataset.conditions)

        condition = dataset.conditions{conditionIndex};

        for repetitionIndex = 1:numel(dataset.repetitions)

            repetition = dataset.repetitions{repetitionIndex};
            sampleName = [condition repetition];
            inputFile = fullfile(inputRoot, [sampleName '_75.mat']);

            assert(isfile(inputFile), 'Input file not found: %s', inputFile);
            inputData = load(inputFile);
            assert(isfield(inputData, 'p_data_adjusted'), ...
                'Variable p_data_adjusted is missing from %s.', inputFile);
            assert(isfield(inputData, 'fs'), ...
                'Variable fs is missing from %s.', inputFile);

            pressureZ = double(inputData.p_data_adjusted(:));
            fs = double(inputData.fs);
            assert(isscalar(fs) && isfinite(fs) && fs > 0, ...
                'Invalid sampling rate in %s.', inputFile);

            % Use the same A-weighting design and filtering operation as
            % Aspectrogram_2.m. Filter the complete signal before cropping.
            [bA, aA] = designAWeighting(fs);
            pressureA = filter(bA, aA, pressureZ);

            levelResult = calculateZAndALevels( ...
                pressureZ, pressureA, fs, pRef, analysisTimeRange, ...
                frameDuration, overlapFraction);

            resultIndex = resultIndex + 1;
            results(resultIndex).Category = dataset.label;
            results(resultIndex).Dataset = dataset.name;
            results(resultIndex).Condition = condition;
            results(resultIndex).Repetition = repetition;
            results(resultIndex).Sample = sampleName;
            results(resultIndex).File = inputFile;
            results(resultIndex).fs = fs;
            results(resultIndex).AnalysisTimeRange_s = analysisTimeRange;
            results(resultIndex).FrameTime_s = levelResult.time;
            results(resultIndex).FrameLZ_dB = levelResult.LZ;
            results(resultIndex).FrameLA_dBA = levelResult.LA;
            results(resultIndex).FrameDifference_ZminusA_dB = ...
                levelResult.LZminusLA;
            results(resultIndex).OverallLZ_dB = levelResult.overallLZ;
            results(resultIndex).OverallLA_dBA = levelResult.overallLA;
            results(resultIndex).Difference_ZminusA_dB = ...
                levelResult.overallLZminusLA;
        end
    end
end

assert(resultIndex == totalSamples, ...
    'Processed sample count does not match the expected count.');

%% ========================= FPRINTF SUMMARY =============================
% Display one line for every recording; no MAT or CSV files are written.
fprintf('\n');
fprintf('=========================================================================\n');
fprintf('Z- AND A-WEIGHTED LEVEL DIFFERENCE FOR EVERY SAMPLE (%.1f-%.1f s)\n', ...
    analysisTimeRange(1), analysisTimeRange(2));
fprintf('Difference is defined as LZ - LA.\n');
fprintf('=========================================================================\n');
fprintf('%-10s %-18s %10s %10s %14s\n', ...
    'Category', 'Sample', 'LZ (dB)', 'LA (dBA)', 'LZ-LA (dB)');
fprintf('%s\n', repmat('-', 1, 68));

for sampleIndex = 1:numel(results)
    fprintf('%-10s %-18s %10.3f %10.3f %14.3f\n', ...
        results(sampleIndex).Category, ...
        results(sampleIndex).Sample, ...
        results(sampleIndex).OverallLZ_dB, ...
        results(sampleIndex).OverallLA_dBA, ...
        results(sampleIndex).Difference_ZminusA_dB);
end

fprintf('%s\n', repmat('-', 1, 68));
fprintf('Processed %d recordings.\n', numel(results));

%% ========================= LOCAL FUNCTIONS =============================

function levelResult = calculateZAndALevels( ...
        pressureZ, pressureA, fs, pRef, timeRange, ...
        frameDuration, overlapFraction)
% Calculate overall and time-varying Z/A-weighted SPL in a common interval.

    assert(numel(pressureZ) == numel(pressureA), ...
        'Z- and A-weighted signals must have equal lengths.');

    nSamples = numel(pressureZ);
    signalTime = (0:nSamples-1).' / fs;
    intervalMask = signalTime >= timeRange(1) & ...
                   signalTime <= timeRange(2);
    assert(nnz(intervalMask) >= 2, ...
        'Requested time range %.3f-%.3f s is unavailable.', ...
        timeRange(1), timeRange(2));

    segmentZ = pressureZ(intervalMask);
    segmentA = pressureA(intervalMask);
    overallRmsZ = sqrt(mean(segmentZ.^2));
    overallRmsA = sqrt(mean(segmentA.^2));
    overallLZ = 20 * log10(max(overallRmsZ, realmin) / pRef);
    overallLA = 20 * log10(max(overallRmsA, realmin) / pRef);

    frameLength = round(frameDuration * fs);
    frameHop = round(frameLength * (1 - overlapFraction));
    assert(frameLength >= 2 && frameHop >= 1, ...
        'Frame duration or overlap produces an invalid frame size.');
    assert(nSamples >= frameLength, ...
        'The recording is shorter than one analysis frame.');

    frameStarts = 1:frameHop:(nSamples - frameLength + 1);
    frameCenters = ((frameStarts - 1) + (frameLength - 1) / 2) / fs;
    frameMask = frameCenters >= timeRange(1) & ...
                frameCenters <= timeRange(2);
    frameStarts = frameStarts(frameMask);
    frameCenters = frameCenters(frameMask);
    assert(~isempty(frameStarts), ...
        'No complete SPL frames lie in %.3f-%.3f s.', ...
        timeRange(1), timeRange(2));

    frameLZ = zeros(numel(frameStarts), 1);
    frameLA = zeros(numel(frameStarts), 1);

    for frameIndex = 1:numel(frameStarts)
        sampleIndices = frameStarts(frameIndex) + (0:frameLength-1);
        rmsZ = sqrt(mean(pressureZ(sampleIndices).^2));
        rmsA = sqrt(mean(pressureA(sampleIndices).^2));
        frameLZ(frameIndex) = 20 * log10(max(rmsZ, realmin) / pRef);
        frameLA(frameIndex) = 20 * log10(max(rmsA, realmin) / pRef);
    end

    levelResult.time = frameCenters(:);
    levelResult.LZ = frameLZ;
    levelResult.LA = frameLA;
    levelResult.LZminusLA = frameLZ - frameLA;
    levelResult.overallLZ = overallLZ;
    levelResult.overallLA = overallLA;
    levelResult.overallLZminusLA = overallLZ - overallLA;
end

function [bA, aA] = designAWeighting(fs)
% Same bilinear-transform A-weighting implementation as Aspectrogram_2.m.

    f1 = 20.598997;
    f2 = 107.65265;
    f3 = 737.86223;
    f4 = 12194.217;
    A1000 = 1.9997;

    numerator = [(2*pi*f4)^2 * 10^(A1000/20), 0, 0, 0, 0];
    denominator = conv([1, 4*pi*f4, (2*pi*f4)^2], ...
        [1, 4*pi*f1, (2*pi*f1)^2]);
    denominator = conv(conv(denominator, [1, 2*pi*f3]), ...
        [1, 2*pi*f2]);

    [bA, aA] = bilinear(numerator, denominator, fs);
end
