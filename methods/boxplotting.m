%% Boxplots of three-repeat-averaged time-varying SQM values
clc;
clear;
close all;

%% ========================= USER SETTINGS ===============================

drone1ResultRoot = fullfile('SQMresults', 'drone10802');
drone2ResultRoot = fullfile('SQMresults', 'drone20814');
violinResultRoot = fullfile('SQMresults', 'violin0804');

% Two drone categories (9 RPMs each) and 5 violin pitches;
% every condition has 3 repeats.
drone1RPMs = {'3428', '4455', '5816', '7119', '8397', ...
              '9504', '10554', '11476', '12547'};
drone2RPMs = {'2125', '3456', '4541', '5424', '6387', ...
              '7213', '8467', '9423', '10377'};
droneNumbers = {'rpm01', 'rpm02', 'rpm03'};

keycollection = {'E3', 'Gsharp3', 'B3', 'C4', 'Csharp4'};
violinNumbers = {'01', '02', '03'};

% Only values with original timestamps from 2 to 12 s are used.
% This is applied again here even when run_all_8_SQM.m has already trimmed
% the MAT files, so older full-duration result files are also handled safely.
plotTimeRange = [2, 12];

% save_png = false;
% save_fig = false;
save_png = true;
save_fig = true;
image_resolution = 600;
boxplotFigureDir = fullfile('SQMresults', 'boxplots');
individualFigureDir = fullfile(boxplotFigureDir, 'Individual');
combinedFigureDir = fullfile(boxplotFigureDir, 'Combined');

% Style inherited from the original boxplotting.m.
box_color = 'k';
box_width = 0.30;
box_line_width = 1.50;
summary_line_width = 1.50;
summary_marker_size = 4;

% Each result file must contain OUT.time and the indicated instantaneous field.
% PAZ = Zwicker/Fastl, PAM = More, PAD = Di et al.
metrics = struct( ...
    'name',      {'Loudness', 'Sharpness', 'Roughness', 'Tonality', ...
                  'Fluctuation Strength', 'PAZ', 'PAM', 'PAD'}, ...
    'fileStem',  {'Loudness', 'Sharpness', 'Roughness', 'Tonality', ...
                  'FluctuationStrength', 'PAZ', 'PAM', 'PAD'}, ...
    'suffix',    {'_N.mat', '_S.mat', '_R.mat', '_K.mat', ...
                  '_FS.mat', '_PAZ.mat', '_PAM.mat', '_PAD.mat'}, ...
    'fieldName', {'InstantaneousLoudness', 'InstantaneousSharpness', ...
                  'InstantaneousRoughness', 'InstantaneousTonality', ...
                  'InstantaneousFluctuationStrength', 'InstantaneousPA', ...
                  'InstantaneousPA', 'InstantaneousPA'}, ...
    'yLabel',    {'Loudness (sone)', 'Sharpness (acum)', ...
                  'Roughness (asper)', 'Tonality (t.u.)', ...
                  'Fluctuation Strength (vacil)', ...
                  'Psychoacoustic Annoyance, PAZ', ...
                  'Psychoacoustic Annoyance, PAM', ...
                  'Psychoacoustic Annoyance, PAD'}, ...
    'whisker',   {10, 10, 10, 10, 10, 10, 10, 10});
    % 'whisker',   {Inf, Inf, Inf, Inf, Inf, Inf, Inf, Inf});

if ~exist(boxplotFigureDir, 'dir')
    mkdir(boxplotFigureDir);
end
if ~exist(individualFigureDir, 'dir')
    mkdir(individualFigureDir);
end
if ~exist(combinedFigureDir, 'dir')
    mkdir(combinedFigureDir);
end

%% ========== PHASE 1: ANALYSE DATA AND DRAW INDIVIDUAL BOXPLOTS =========

% Retain all averaged curves and summary values for optional later analysis.
boxplotData = struct;
individualFigureCounter = 0;

for metricIndex = 1:numel(metrics)

    metric = metrics(metricIndex);

    fprintf('\n===============================================================\n');
    fprintf('%s\n', upper(metric.name));
    fprintf('===============================================================\n');

    [drone1MeanTime, drone1MeanCurves, drone1MeanValues, drone1P95Values] = ...
        averageRepeatedConditionCurves( ...
            drone1ResultRoot, drone1RPMs, droneNumbers, ...
            metric.suffix, metric.fieldName, plotTimeRange);

    [drone2MeanTime, drone2MeanCurves, drone2MeanValues, drone2P95Values] = ...
        averageRepeatedConditionCurves( ...
            drone2ResultRoot, drone2RPMs, droneNumbers, ...
            metric.suffix, metric.fieldName, plotTimeRange);

    [violinMeanTime, violinMeanCurves, violinMeanValues, violinP95Values] = ...
        averageRepeatedConditionCurves( ...
            violinResultRoot, keycollection, violinNumbers, ...
            metric.suffix, metric.fieldName, plotTimeRange);

    % Use one shared adaptive Y-axis range for both drones and violin.
    commonYLim = calculateCommonYLim( ...
        {drone1MeanCurves, drone2MeanCurves, violinMeanCurves}, 0.08);

    printSummaryTable('DRONE 1 (5-inch, 3-blade)', 'RPM', drone1RPMs, ...
                      drone1MeanValues, drone1P95Values);
    printSummaryTable('DRONE 2 (7-inch, 3-blade)', 'RPM', drone2RPMs, ...
                      drone2MeanValues, drone2P95Values);
    printSummaryTable('VIOLIN', 'Pitch', keycollection, ...
                      violinMeanValues, violinP95Values);

    % Save data into a valid structure field (for example, FluctuationStrength).
    dataField = matlab.lang.makeValidName(metric.fileStem);
    boxplotData.(dataField).drone1.description = 'Drone 1 (5-inch, 3-blade)';
    boxplotData.(dataField).drone1.labels = drone1RPMs;
    boxplotData.(dataField).drone1.time = drone1MeanTime;
    boxplotData.(dataField).drone1.curves = drone1MeanCurves;
    boxplotData.(dataField).drone1.mean = drone1MeanValues;
    boxplotData.(dataField).drone1.p95 = drone1P95Values;
    boxplotData.(dataField).drone2.description = 'Drone 2 (7-inch, 3-blade)';
    boxplotData.(dataField).drone2.labels = drone2RPMs;
    boxplotData.(dataField).drone2.time = drone2MeanTime;
    boxplotData.(dataField).drone2.curves = drone2MeanCurves;
    boxplotData.(dataField).drone2.mean = drone2MeanValues;
    boxplotData.(dataField).drone2.p95 = drone2P95Values;
    boxplotData.(dataField).violin.labels = keycollection;
    boxplotData.(dataField).violin.time = violinMeanTime;
    boxplotData.(dataField).violin.curves = violinMeanCurves;
    boxplotData.(dataField).violin.mean = violinMeanValues;
    boxplotData.(dataField).violin.p95 = violinP95Values;

    boxplotData.(dataField).timeRange_s = plotTimeRange;

    drone1Labels = cellfun(@(x) [x ' '], drone1RPMs, ...
                           'UniformOutput', false);
    drone2Labels = cellfun(@(x) [x ' '], drone2RPMs, ...
                           'UniformOutput', false);

    individualFigureCounter = individualFigureCounter + 1;
    individualFig = makeSQMBoxplot( ...
        drone1MeanCurves, drone1Labels, drone1MeanValues, drone1P95Values, ...
        metric, 'Drone 1 (5-inch, 3-blade)', box_color, box_width, box_line_width, ...
        summary_line_width, summary_marker_size, commonYLim, [80, 80, 900, 500]);

    saveBoxplotFigure(individualFig, ...
        fullfile(individualFigureDir, ...
                 [metric.fileStem '_drone1_boxplot']), ...
        save_png, save_fig, image_resolution);
    close(individualFig);

    individualFigureCounter = individualFigureCounter + 1;
    individualFig = makeSQMBoxplot( ...
        drone2MeanCurves, drone2Labels, drone2MeanValues, drone2P95Values, ...
        metric, 'Drone 2 (7-inch, 3-blade)', box_color, box_width, box_line_width, ...
        summary_line_width, summary_marker_size, commonYLim, [80, 80, 900, 500]);

    saveBoxplotFigure(individualFig, ...
        fullfile(individualFigureDir, ...
                 [metric.fileStem '_drone2_boxplot']), ...
        save_png, save_fig, image_resolution);
    close(individualFig);

    individualFigureCounter = individualFigureCounter + 1;
    individualFig = makeSQMBoxplot( ...
        violinMeanCurves, keycollection, violinMeanValues, violinP95Values, ...
        metric, 'Violin', box_color, box_width, box_line_width, ...
        summary_line_width, summary_marker_size, commonYLim, [80, 80, 600, 500]);

    saveBoxplotFigure(individualFig, ...
        fullfile(individualFigureDir, ...
                 [metric.fileStem '_violin_boxplot']), ...
        save_png, save_fig, image_resolution);
    close(individualFig);
end

% Save the processed data before entering the independent summary loop.
save(fullfile(boxplotFigureDir, 'SQM_boxplot_data.mat'), ...
     'boxplotData', 'drone1RPMs', 'drone2RPMs', 'keycollection', ...
     'plotTimeRange', 'metrics');

fprintf('\nGenerated and saved %d individual boxplot figures.\n', ...
        individualFigureCounter);
fprintf('Individual boxplots: %s\n', individualFigureDir);

%% ================ PHASE 2: DRAW COMBINED SQM FIGURES ==================

% This second loop uses only the already processed data in boxplotData.
% It does not reload the individual MAT files or recompute repeat averages.
combinedFigures = gobjects(numel(metrics), 1);
combinedFigureCounter = 0;
save_fig = true;
save_png = true;
combinedFigureDir2 = 'C:\Users\94780\Documents\LNA\2026\JASAtrytry\JASA_LaTeXPackage\revision1_track\';

for metricIndex = 1:numel(metrics)

    metric = metrics(metricIndex);
    dataField = matlab.lang.makeValidName(metric.fileStem);
    metricData = boxplotData.(dataField);

    drone1MeanCurves = metricData.drone1.curves;
    drone1MeanValues = metricData.drone1.mean;
    drone1P95Values = metricData.drone1.p95;
    drone2MeanCurves = metricData.drone2.curves;
    drone2MeanValues = metricData.drone2.mean;
    drone2P95Values = metricData.drone2.p95;
    violinMeanCurves = metricData.violin.curves;
    violinMeanValues = metricData.violin.mean;
    violinP95Values = metricData.violin.p95;

    drone1Labels = cellfun(@(x) [x], ...
        metricData.drone1.labels, 'UniformOutput', false);
    drone2Labels = cellfun(@(x) [x], ...
        metricData.drone2.labels, 'UniformOutput', false);
    violinLabels = metricData.violin.labels;

    % Recreate the common Y limits from the cached curves so the summary
    % loop remains self-contained.
    commonYLim = calculateCommonYLim( ...
        {drone1MeanCurves, drone2MeanCurves, violinMeanCurves}, 0.08);

    combinedFigureCounter = combinedFigureCounter + 1;
    combinedFig = figure( ...
        'Color', 'w', ...
        'Name', [metric.name ' - Combined Boxplots'], ...
        'NumberTitle', 'off', ...
        'Position', [30, 80, 1900, 570]);
    combinedFigures(metricIndex) = combinedFig;

    combinedLayout = tiledlayout(combinedFig, 1, 3, ...
        'TileSpacing', 'compact', 'Padding', 'compact');

    ax1 = nexttile(combinedLayout);
    ax2 = nexttile(combinedLayout);
    ax3 = nexttile(combinedLayout);
    
    drawSQMBoxplot(ax1, drone1MeanCurves, drone1Labels, ...
        drone1MeanValues, drone1P95Values, metric, ...
        'Drone 1 (5-inch, 3-blade)', box_color, box_width, ...
        box_line_width, summary_line_width, summary_marker_size, ...
        commonYLim, true, false);

    drawSQMBoxplot(ax2, drone2MeanCurves, drone2Labels, ...
        drone2MeanValues, drone2P95Values, metric, ...
        'Drone 2 (7-inch, 3-blade)', box_color, box_width, ...
        box_line_width, summary_line_width, summary_marker_size, ...
        commonYLim, true, false);

    drawSQMBoxplot(ax3, violinMeanCurves, violinLabels, ...
        violinMeanValues, violinP95Values, metric, 'Violin', ...
        box_color, box_width, box_line_width, summary_line_width, ...
        summary_marker_size, commonYLim, true, false);

    xlabel(combinedLayout, 'Operating condition', ...
        'FontSize', 20, 'FontWeight', 'bold');
    ylabel(combinedLayout, metric.yLabel, ...
        'FontSize', 20, 'FontWeight', 'bold');
%     title(combinedLayout, ...
%         sprintf('%s Boxplots: Drone 1, Drone 2 and Violin', ...
%                 metric.name), ...
%         'FontSize', 18, 'FontWeight', 'bold');

    saveBoxplotFigure(combinedFig, ...
        fullfile(combinedFigureDir, ...
                 [metric.fileStem '_all_3_categories_boxplot']), ...
        save_png, save_fig, image_resolution);
end

fprintf('\nGenerated, displayed and saved %d combined SQM figures.\n', ...
        combinedFigureCounter);
fprintf('Combined SQM figures: %s\n', combinedFigureDir);
fprintf('Averaged boxplot data: %s\n', boxplotFigureDir);

%% ========================= LOCAL FUNCTIONS =============================

function [meanTimes, meanCurves, meanValues, p95Values] = ...
    averageRepeatedConditionCurves(resultRoot, conditions, samples, ...
                                   suffix, fieldName, timeRange)

nConditions = numel(conditions);
nSamples = numel(samples);
meanTimes = cell(nConditions, 1);
meanCurves = cell(nConditions, 1);
meanValues = nan(nConditions, 1);
p95Values = nan(nConditions, 1);

for conditionIndex = 1:nConditions

    conditionName = conditions{conditionIndex};
    repeatCurves = cell(nSamples, 1);
    repeatTimes = cell(nSamples, 1);

    for sampleIndex = 1:nSamples

        sampleName = samples{sampleIndex};
        filePath = fullfile(resultRoot, conditionName, ...
                            [conditionName sampleName suffix]);

        assert(isfile(filePath), 'Result file not found: %s', filePath);
        loaded = load(filePath, 'OUT');
        assert(isfield(loaded, 'OUT'), ...
               'Variable OUT not found in %s', filePath);
        assert(isfield(loaded.OUT, fieldName), ...
               'Field OUT.%s not found in %s', fieldName, filePath);
        assert(isfield(loaded.OUT, 'time'), ...
               'Field OUT.time not found in %s', filePath);

        curveData = loaded.OUT.(fieldName);
        repeatCurves{sampleIndex} = curveData(:);
        repeatTimes{sampleIndex} = loaded.OUT.time(:);

        assert(numel(repeatCurves{sampleIndex}) == ...
               numel(repeatTimes{sampleIndex}), ...
               'OUT.%s and OUT.time have different lengths in %s', ...
               fieldName, filePath);
        assert(numel(repeatTimes{sampleIndex}) >= 2, ...
               'At least two time points are required in %s', filePath);

        timeMask = repeatTimes{sampleIndex} >= timeRange(1) & ...
                   repeatTimes{sampleIndex} <= timeRange(2);
        assert(nnz(timeMask) >= 2, ...
               'Fewer than two samples lie in %.3g-%.3g s in %s.', ...
               timeRange(1), timeRange(2), filePath);
        repeatTimes{sampleIndex} = repeatTimes{sampleIndex}(timeMask);
        repeatCurves{sampleIndex} = repeatCurves{sampleIndex}(timeMask);
    end

    % Use the longest repeat as the reference grid inside the common time
    % overlap. Interpolation is deliberately restricted to this overlap, so
    % no artificial extrapolated values enter the boxplot.
    [~, referenceIndex] = max(cellfun(@numel, repeatTimes));
    referenceTime = repeatTimes{referenceIndex};
    commonStart = max(cellfun(@(x) x(1), repeatTimes));
    commonEnd = min(cellfun(@(x) x(end), repeatTimes));
    referenceTime = referenceTime(referenceTime >= commonStart & ...
                                  referenceTime <= commonEnd);
    assert(numel(referenceTime) >= 2, ...
           'No sufficient common time overlap for condition %s.', conditionName);
    curveMatrix = nan(numel(referenceTime), nSamples);

    for sampleIndex = 1:nSamples
        [uniqueTime, uniqueIndices] = unique(repeatTimes{sampleIndex}, 'stable');
        uniqueCurve = repeatCurves{sampleIndex}(uniqueIndices);
        assert(numel(uniqueTime) >= 2, ...
               'Fewer than two unique time points in condition %s.', ...
               conditionName);
        curveMatrix(:,sampleIndex) = interp1( ...
            uniqueTime, uniqueCurve, referenceTime, 'linear');
    end

    averagedCurve = mean(curveMatrix, 2, 'omitnan');
    meanTimes{conditionIndex} = referenceTime;
    meanCurves{conditionIndex} = averagedCurve;
    meanValues(conditionIndex) = mean(averagedCurve, 'omitnan');
    p95Values(conditionIndex) = percentile95(averagedCurve);
end
end

function fig = makeSQMBoxplot(curves, labels, meanValues, p95Values, ...
                              metric, sourceName, boxColor, boxWidth, ...
                              boxLineWidth, summaryLineWidth, markerSize, ...
                              commonYLim, figureSize)

fig = figure('Color', 'w', ...
             'Name', [metric.name ' - ' sourceName ' Boxplot'], ...
             'NumberTitle', 'off', 'Position', figureSize);
ax = axes(fig);
drawSQMBoxplot(ax, curves, labels, meanValues, p95Values, ...
    metric, sourceName, boxColor, boxWidth, boxLineWidth, ...
    summaryLineWidth, markerSize, commonYLim, true, true);
end

function drawSQMBoxplot(ax, curves, labels, meanValues, p95Values, ...
                        metric, sourceName, boxColor, boxWidth, ...
                        boxLineWidth, summaryLineWidth, markerSize, ...
                        commonYLim, showLegend, showAxisLabels)

% Long-form input allows different averaged-curve lengths among conditions.
allValues = [];
groupIndices = [];
for conditionIndex = 1:numel(curves)
    curve = curves{conditionIndex};
    curve = curve(isfinite(curve));
    assert(~isempty(curve), ...
           'No finite %s data for %s condition %s.', ...
           metric.name, sourceName, labels{conditionIndex});
    allValues = [allValues; curve(:)]; %#ok<AGROW>
    groupIndices = [groupIndices; ...
                    repmat(conditionIndex, numel(curve), 1)]; %#ok<AGROW>
end

axes(ax); 
hold(ax, 'on');

h = boxplot(allValues, groupIndices, ...
    'Labels', labels, ...
    'Colors', boxColor, ...
    'BoxStyle', 'outline', ...
    'Whisker', metric.whisker, ...
    'Widths', boxWidth, ...
    'Symbol', '');
    % 'Symbol', 'k+');
set(h, 'LineWidth', boxLineWidth);

positions = 1:numel(labels);
meanLine = plot(ax, positions, meanValues, 'k-o', ...
     'LineWidth', summaryLineWidth, 'MarkerSize', markerSize, ...
     'MarkerFaceColor', 'w', 'DisplayName', 'Mean value');
p95Line = plot(ax, positions, p95Values, 'k--o', ...
     'LineWidth', summaryLineWidth, 'MarkerSize', markerSize, ...
     'MarkerFaceColor', 'w', ...
     'DisplayName', '5% exceeded value');

ax.FontSize = 16;
ax.XGrid = 'off';
ax.YGrid = 'on';
ax.Box = 'on';

% Use the same adaptive Y-axis range for Drone 1, Drone 2 and Violin.
ylim(ax, commonYLim);

if numel(labels) > 5
    ax.XTickLabelRotation = 35;
end

if showAxisLabels
    xlabel(ax, sourceAxisLabel(sourceName), ...
           'FontSize', 14, 'FontWeight', 'bold');
    ylabel(ax, metric.yLabel, 'FontSize', 14, 'FontWeight', 'bold');
    panelTitle = sprintf('%s: %s', metric.name, sourceName);
else
    panelTitle = sourceName;
end
title(ax, panelTitle, 'FontSize', 20, 'FontWeight', 'bold');

if showLegend
    legend(ax, [meanLine, p95Line], ...
           {'Mean value', '5% exceeded value'}, ...
           'Location', 'best', 'Box', 'on', 'FontSize', 17);
end
hold(ax, 'off');
end

function commonYLim = calculateCommonYLim(curveGroups, paddingRatio)

allCurves = {};
for groupIndex = 1:numel(curveGroups)
    allCurves = [allCurves; curveGroups{groupIndex}(:)]; %#ok<AGROW>
end
allValues = [];

for i = 1:numel(allCurves)
    curve = allCurves{i};
    curve = curve(isfinite(curve));
    allValues = [allValues; curve(:)]; %#ok<AGROW>
end

assert(~isempty(allValues), ...
       'Cannot calculate Y-axis limits because no finite data were found.');

dataMin = min(allValues);
dataMax = max(allValues);
dataRange = dataMax - dataMin;

% Handle the special case where every value is identical
if dataRange == 0
    if dataMax == 0
        padding = 1;
    else
        padding = 0.08 * abs(dataMax);
    end
else
    padding = paddingRatio * dataRange;
end

commonYLim = [dataMin - padding, dataMax + padding];

end

function labelText = sourceAxisLabel(sourceName)
if startsWith(sourceName, 'Drone', 'IgnoreCase', true)
    labelText = 'Rotor speed (RPM)';
else
    labelText = 'Violin pitch';
end
end

function value = percentile95(data)
data = data(isfinite(data));
if isempty(data)
    value = NaN;
else
    value = prctile(data, 95);
end
end

function printSummaryTable(sourceName, conditionName, conditions, ...
                           meanValues, p95Values)
summaryTable = table(string(conditions(:)), meanValues, p95Values, ...
    'VariableNames', {conditionName, 'Mean', 'P95'});
fprintf('\n%s: THREE-REPEAT-AVERAGED CURVES\n', sourceName);
disp(summaryTable);
end

function saveBoxplotFigure(fig, basePath, savePng, saveFig, resolution)
if savePng
    exportgraphics(fig, [basePath '.png'], 'Resolution', resolution);
end
if saveFig
    savefig(fig, [basePath '.fig']);
end
end
