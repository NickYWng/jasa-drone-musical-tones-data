%% A-weighted spectrograms averaged across three repeated samples
% For each RPM/pitch: apply A-weighting, calculate the one-sided short-time
% PSD, average the three PSDs in the linear domain, then convert to dBA/Hz.

clc;
clear;
close all;

%% 1. Input files (two drone categories plus violin)
drone1Dir = fullfile('recordings', 'drone10802', '75A_mat');
drone2Dir = fullfile('recordings', 'drone20814', '75A_mat');
violinDir = fullfile('recordings', 'violin0804', '75A_mat');

drone1RPMs = {'3428', '4455', '5816', '7119', '8397', ...
              '9504', '10554', '11476', '12547'};
drone2RPMs = {'2125', '3456', '4541', '5424', '6387', ...
              '7213', '8467', '9423', '10377'};
droneNumbers = {'rpm01', 'rpm02', 'rpm03'};

droneSets = struct( ...
    'label', {'Drone 1', 'Drone 2'}, ...
    'shortLabel', {'Drone1', 'Drone2'}, ...
    'propLabel', {'5-inch, 3-blade', '7-inch, 3-blade'}, ...
    'directory', {drone1Dir, drone2Dir}, ...
    'rpms', {drone1RPMs, drone2RPMs});

keyCollection = {'E3', 'Gsharp3', 'B3', 'C4', 'Csharp4'};
pitchFundamentalHz = [164.8138, 207.6523, 246.9417, ...
                      261.6256, 277.1826]; % equal temperament, A4 = 440 Hz
violinNumbers = {'01', '02', '03'};

%% 2. Spectrogram and plotting parameters (Aspectrogram_old.m style)
pRef = 20e-6;                 % reference sound pressure, Pa
windowDuration = 0.030;       % 30 ms Hann window
overlapFraction = 0.75;       % 75% overlap
frequencyRange = [0 4500];    % displayed range, Hz
colorRange = [20 100];        % common color limits, dBA/Hz
figureResolution = 300;       % exported PNG resolution, dpi
save_fig = true;              % save both PNG and editable MATLAB FIG files
plotTimeRange = [2 12];       % retain original timestamps from 2 to 12 s
bladeCount = 3;               % both Drone 1 and Drone 2 use 3-blade props
bpfToleranceFraction = 0.05;  % nominal RPM uncertainty band: +/-5%

%% 3. Output directories
outputRoot = fullfile(pwd, 'SQMresults', ...
    'Aspectrogram_outputs');
drone1FigureDir = fullfile(outputRoot, 'Drone1_Individual');
drone2FigureDir = fullfile(outputRoot, 'Drone2_Individual');
violinFigureDir = fullfile(outputRoot, 'Violin_Individual');

if ~exist(drone1FigureDir, 'dir')
    mkdir(drone1FigureDir);
end
if ~exist(drone2FigureDir, 'dir')
    mkdir(drone2FigureDir);
end
if ~exist(violinFigureDir, 'dir')
    mkdir(violinFigureDir);
end

%% 4. Two drone categories: three-sample PSD average for each RPM
droneSpectrograms = cell(numel(droneSets), 1);
droneFigureDirs = {drone1FigureDir, drone2FigureDir};

for d = 1:numel(droneSets)
    droneSet = droneSets(d);
    currentSpectrograms = cell(numel(droneSet.rpms), 1);

    fprintf('\n============================================================\n');
    fprintf('%s: A-WEIGHTED THREE-SAMPLE PSD AVERAGE\n', ...
        upper(droneSet.label));
    fprintf('============================================================\n');

    for i = 1:numel(droneSet.rpms)
        rpm = droneSet.rpms{i};
        fileList = cell(numel(droneNumbers), 1);

        for j = 1:numel(droneNumbers)
            fileList{j} = fullfile(droneSet.directory, ...
                [rpm droneNumbers{j} '_75.mat']);
        end

        fprintf('\nProcessing %s RPM %s\n', droneSet.label, rpm);
        result = averageAWeightedPSD(fileList, pRef, windowDuration, ...
            overlapFraction, frequencyRange, plotTimeRange);
        result.Category = droneSet.label;
        result.Propeller = droneSet.propLabel;
        result.RPM = rpm;
        result.files = fileList;
        result.bladeCount = bladeCount;
        result.BPF_Hz = bladeCount * str2double(rpm) / 60;
        frequencyResolution = median(diff(result.frequency));
        bpfHalfWidth = max(bpfToleranceFraction * result.BPF_Hz, ...
            frequencyResolution / 2);
        result.BPF_band_Hz = [max(0, result.BPF_Hz - bpfHalfWidth), ...
            result.BPF_Hz + bpfHalfWidth];
        currentSpectrograms{i} = result;

        fig = figure('Color', 'w', ...
            'Name', [droneSet.label ' (' droneSet.propLabel ') - ' ...
                     rpm ' RPM'], ...
            'NumberTitle', 'off', 'Position', [100 100 700 500]);
        plotOldStyleSpectrogram(gca, result.time, result.frequency, ...
            result.spectrum_dBA_per_Hz, colorRange, plotTimeRange);
        markFrequencyRegion(gca, plotTimeRange, result.BPF_Hz, ...
            result.BPF_band_Hz, result.BPF_Hz, true, ...
            'BPF', '3-blade BPF');
        title([droneSet.label ' (' droneSet.propLabel ') - ' rpm ...
               ' RPM A-weighted spectrogram'], ...
            'FontSize', 18, 'FontWeight', 'bold');

        outputFile = fullfile(droneFigureDirs{d}, ...
            [droneSet.shortLabel '_' rpm 'RPM_75A.png']);

        if save_fig
            saveFigurePair(fig, outputFile, figureResolution);
        end

        close(fig);
    end

    droneSpectrograms{d} = currentSpectrograms;
end

drone1Spectrogram = droneSpectrograms{1};
drone2Spectrogram = droneSpectrograms{2};

%% 5. Violin: three-sample PSD average for each pitch
violinSpectrogram = cell(numel(keyCollection), 1);

fprintf('\n============================================================\n');
fprintf('VIOLIN: A-WEIGHTED THREE-SAMPLE PSD AVERAGE\n');
fprintf('============================================================\n');

for i = 1:numel(keyCollection)
    pitch = keyCollection{i};
    fileList = cell(numel(violinNumbers), 1);

    for j = 1:numel(violinNumbers)
        % Example: recordings/violin0804/75A_mat/E301_75.mat
        fileList{j} = fullfile(violinDir, ...
            [pitch violinNumbers{j} '_75.mat']);
    end

    fprintf('\nProcessing violin pitch %s\n', pitch);
    result = averageAWeightedPSD(fileList, pRef, windowDuration, ...
        overlapFraction, frequencyRange, plotTimeRange);
    result.Pitch = pitch;
    result.files = fileList;
    result.Fundamental_Hz = pitchFundamentalHz(i);
    frequencyResolution = median(diff(result.frequency));
    fundamentalHalfWidth = frequencyResolution / 2;
    result.Fundamental_band_Hz = ...
        [max(0, result.Fundamental_Hz - fundamentalHalfWidth), ...
         result.Fundamental_Hz + fundamentalHalfWidth];
    violinSpectrogram{i} = result;

    fig = figure('Color', 'w', 'Name', ['Violin ' pitch], ...
        'NumberTitle', 'off', 'Position', [100 100 700 500]);
    plotOldStyleSpectrogram(gca, result.time, result.frequency, ...
        result.spectrum_dBA_per_Hz, colorRange, plotTimeRange);
%     markFrequencyRegion(gca, plotTimeRange, result.Fundamental_Hz, ...
%         result.Fundamental_band_Hz, result.Fundamental_Hz, true, ...
%         'Fundamental', [displayPitch(pitch) ' fundamental']);
    title([displayPitch(pitch) ' A-weighted spectrogram'], ...
        'FontSize', 18, 'FontWeight', 'bold');

    outputFile = fullfile(violinFigureDir, ...
        ['Violin_' pitch '_75A.png']);
    if save_fig
        saveFigurePair(fig, outputFile, figureResolution);
    end
    close(fig);
end

%% 6. Summary: all nine RPMs, one clearly labelled figure per drone
for d = 1:numel(droneSets)
    droneSet = droneSets(d);
    currentSpectrograms = droneSpectrograms{d};

    figDrone = figure('Color', 'w', ...
        'Name', [droneSet.label ' A-weighted spectrogram summary'], ...
        'NumberTitle', 'off', 'Position', [40 40 1500 1000]);
    layoutDrone = tiledlayout(figDrone, 3, 3, ...
        'TileSpacing', 'compact', 'Padding', 'compact');

    for i = 1:numel(droneSet.rpms)
        ax = nexttile(layoutDrone);
        lastDroneAx = ax;
        result = currentSpectrograms{i};
        plotSummaryPanel(ax, result.time, result.frequency, ...
            result.spectrum_dBA_per_Hz, colorRange, plotTimeRange);
        markFrequencyRegion(ax, plotTimeRange, result.BPF_Hz / 1000, ...
            result.BPF_band_Hz / 1000, result.BPF_Hz, false, ...
            'BPF', '3-blade BPF');
        title(ax, [droneSet.label ' (' droneSet.propLabel ') | ' ...
                   droneSet.rpms{i} ' RPM'], ...
            'FontSize', 15, 'FontWeight', 'bold');
    end

    xlabel(layoutDrone, 'Time (s)', 'FontSize', 18, 'FontWeight', 'bold');
    ylabel(layoutDrone, 'Frequency (kHz)', ...
        'FontSize', 18, 'FontWeight', 'bold');
    title(layoutDrone, ...
        [droneSet.label ' (' droneSet.propLabel ...
         ') A-weighted Spectrograms, ' ...
         '(3-sample Linear PSD Average)'], ...
        'FontSize', 20, 'FontWeight', 'bold');
    colormap(figDrone, jet);
    cbDrone = colorbar(lastDroneAx);
    cbDrone.Layout.Tile = 'east';
    cbDrone.FontSize = 16;

    if save_fig
        droneSummaryFile = fullfile(outputRoot, ...
            [droneSet.shortLabel '_AllRPM_Aspec.png']);
        saveFigurePair(figDrone, droneSummaryFile, figureResolution);
    end
end

%% 7. Summary: all five violin pitches
figViolin = figure('Color', 'w', ...
    'Name', 'Violin A-weighted spectrogram summary', ...
    'NumberTitle', 'off', 'Position', [60 60 1500 760]);
layoutViolin = tiledlayout(figViolin, 2, 3, ...
    'TileSpacing', 'compact', 'Padding', 'compact');

for i = 1:numel(keyCollection)
    ax = nexttile(layoutViolin);
    lastViolinAx = ax;
    result = violinSpectrogram{i};
    plotSummaryPanel(ax, result.time, result.frequency, ...
        result.spectrum_dBA_per_Hz, colorRange, plotTimeRange);
%     markFrequencyRegion(ax, plotTimeRange, ...
%         result.Fundamental_Hz / 1000, ...
%         result.Fundamental_band_Hz / 1000, ...
%         result.Fundamental_Hz, false, ...
%         'Fundamental', [displayPitch(keyCollection{i}) ' fundamental']);
    title(ax, displayPitch(keyCollection{i}), ...
        'FontSize', 16, 'FontWeight', 'bold');
end

emptyAx = nexttile(layoutViolin);
axis(emptyAx, 'off');
xlabel(layoutViolin, 'Time (s)', 'FontSize', 18, 'FontWeight', 'bold');
ylabel(layoutViolin, 'Frequency (kHz)', 'FontSize', 18, 'FontWeight', 'bold');
title(layoutViolin, ...
    'Violin A-weighted Spectrograms, (3-sample Linear PSD Average)', ...
    'FontSize', 20, 'FontWeight', 'bold');
colormap(figViolin, jet);
cbViolin = colorbar(lastViolinAx);
cbViolin.Layout.Tile = 'east';
% cbViolin.Label.String = 'A-weighted PSD level (dBA/Hz)';
cbViolin.FontSize = 16;

if save_fig
    violinSummaryFile = fullfile(outputRoot, ...
        'Violin_AllPitch_Aspec.png');
    saveFigurePair(figViolin, violinSummaryFile, figureResolution);
end

%%
% Save averaged numerical results for later analysis without rerunning STFT.
save(fullfile(outputRoot, 'Aweighted_spectrogram_PSD_average_data.mat'), ...
    'drone1Spectrogram', 'drone2Spectrogram', 'violinSpectrogram', ...
    'drone1RPMs', 'drone2RPMs', 'keyCollection', ...
    'pitchFundamentalHz', 'plotTimeRange', ...
    'frequencyRange', 'colorRange', 'bladeCount', ...
    'bpfToleranceFraction', ...
    'windowDuration', 'overlapFraction', '-v7.3');

fprintf('\nAll figures and averaged data were saved to:\n%s\n', outputRoot);

%% Local functions
function result = averageAWeightedPSD(fileList, pRef, windowDuration, ...
        overlapFraction, frequencyRange, timeRange)
% Calculate each full-recording spectrogram, then retain timeRange and
% average the repeated linear PSDs. Cropping occurs after filtering/STFT.
    nSamples = numel(fileList);
    PAll = cell(nSamples, 1);
    TAll = cell(nSamples, 1);
    FAll = cell(nSamples, 1);
    fsAll = zeros(nSamples, 1);

    for k = 1:nSamples
        filePath = fileList{k};
        fprintf('  Loading: %s\n', filePath);

        data = load(filePath);

        pressure = double(data.p_data_adjusted(:));
        fs = double(data.fs);
        fsAll(k) = fs;

        [bA, aA] = designAWeighting(fs);
        pressureA = filter(bA, aA, pressure);
        windowLength = round(windowDuration * fs);
        analysisWindow = hann(windowLength);
        nOverlap = round(overlapFraction * windowLength);
        nfft = 2^nextpow2(windowLength);

        % Fourth output: one-sided PSD per time segment in Pa^2/Hz.
        [~, F, T, Pxx] = spectrogram(pressureA, analysisWindow, ...
            nOverlap, nfft, fs);
        PAll{k} = Pxx;
        FAll{k} = F;
        TAll{k} = T;
    end

    FReference = FAll{1};

    commonStart = max([max(cellfun(@(x) x(1), TAll)), timeRange(1)]);
    commonEnd = min([min(cellfun(@(x) x(end), TAll)), timeRange(2)]);

    assert(commonStart < commonEnd, ...
        'Requested time range %.3f-%.3f s is unavailable in these files.', ...
        timeRange(1), timeRange(2));

    timeMask = TAll{1} >= commonStart & TAll{1} <= commonEnd;
    TCommon = TAll{1}(timeMask);

    PStack = zeros(numel(FReference), numel(TCommon), nSamples);
    for k = 1:nSamples
        % Interpolate LINEAR PSD, never dB values.
        PStack(:, :, k) = interp1(TAll{k}, PAll{k}.', ...
            TCommon, 'linear').';
    end

    PAverage = mean(PStack, 3, 'omitnan');
    spectrumDBA = 10 * log10(max(PAverage, realmin) / (pRef^2));
    frequencyMask = FReference >= frequencyRange(1) & ...
        FReference <= min(frequencyRange(2), fsAll(1) / 2);

    result.time = TCommon;
    result.frequency = FReference(frequencyMask);
    result.PSD_Pa2_per_Hz = PAverage(frequencyMask, :);
    result.spectrum_dBA_per_Hz = spectrumDBA(frequencyMask, :);
    result.fs = fsAll(1);
    result.requestedTimeRange = timeRange;
end

function [bA, aA] = designAWeighting(fs)
% Bilinear-transform implementation retained from Aspectrogram_old.m.
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

function plotOldStyleSpectrogram(ax, time, frequency, spectrumDBA, ...
        colorRange, timeRange)
% Match the individual-figure appearance of Aspectrogram_old.m.
    imagesc(ax, time, frequency, spectrumDBA);
    axis(ax, 'xy');
    colormap(ax, jet);
    caxis(ax, colorRange);
    xlim(ax, timeRange);
    ylim(ax, [frequency(1), frequency(end)]);
    ax.FontSize = 13;
    ax.Box = 'on';
    ax.YTick = 0:1000:4500;
    ax.YTickLabel = arrayfun(@(x) sprintf('%.1f', x/1000), ...
        ax.YTick, 'UniformOutput', false);
    xlabel(ax, 'Time (s)', 'FontSize', 15);
    ylabel(ax, 'Frequency (kHz)', 'FontSize', 15, 'FontWeight', 'bold');
    cb = colorbar(ax);
%     cb.FontSize = 10;
%     cb.Label.String = 'A-weighted PSD level (dBA/Hz)';
end

function plotSummaryPanel(ax, time, frequency, spectrumDBA, ...
        colorRange, timeRange)
    imagesc(ax, time, frequency / 1000, spectrumDBA);
    axis(ax, 'xy');
    caxis(ax, colorRange);
    xlim(ax, timeRange);
    ylim(ax, [frequency(1), frequency(end)] / 1000);
    ax.FontSize = 13;
    ax.Box = 'on';
end

function markFrequencyRegion(ax, timeRange, frequencyPlotValue, ...
        bandPlotValues, frequencyHz, showLegend, labelPrefix, legendPrefix)
% Mark a BPF or musical fundamental using the same visual format.
% frequencyPlotValue/bandPlotValues use the current y-axis unit (Hz or
% kHz), while frequencyHz is retained for the displayed label.
    previousHold = ishold(ax);
    hold(ax, 'on');

    bandColor = [1.00 0.82 0.10];
    patch(ax, ...
        [timeRange(1) timeRange(2) timeRange(2) timeRange(1)], ...
        [bandPlotValues(1) bandPlotValues(1) ...
         bandPlotValues(2) bandPlotValues(2)], ...
        bandColor, 'FaceAlpha', 0.20, 'EdgeColor', 'none', ...
        'HandleVisibility', 'off');

    frequencyLine = plot(ax, timeRange, ...
        [frequencyPlotValue frequencyPlotValue], '--', ...
        'Color', bandColor, 'LineWidth', 1.5);

    yLimits = ylim(ax);
    labelY = min(bandPlotValues(2) + 0.025 * diff(yLimits), ...
        yLimits(2) - 0.03 * diff(yLimits));
    text(ax, timeRange(1) + 0.15, labelY, ...
        sprintf('%s ~ %.1f Hz', labelPrefix, frequencyHz), ...
        'Color', 'w', 'FontSize', 10, 'FontWeight', 'bold', ...
        'BackgroundColor', [0.15 0.15 0.15], 'Margin', 1, ...
        'VerticalAlignment', 'bottom');

    if showLegend
        legend(ax, frequencyLine, ...
            sprintf('%s ~ %.1f Hz', legendPrefix, frequencyHz), ...
            'Location', 'northeast', 'FontSize', 10);
    else
        set(frequencyLine, 'HandleVisibility', 'off');
    end

    if ~previousHold
        hold(ax, 'off');
    end
end

function saveFigurePair(fig, pngFile, resolution)
% Save a publication-ready PNG and an editable MATLAB FIG with same name.
    exportgraphics(fig, pngFile, 'Resolution', resolution);
    [folder, baseName] = fileparts(pngFile);
    savefig(fig, fullfile(folder, [baseName '.fig']));
end

function label = displayPitch(pitch)
    label = strrep(pitch, 'sharp', '#');
end
