%% compare_PA_model_correlations.m
% Compare correlations among psychoacoustic annoyance models (PAZ, PAM, PAD)
% within each sample category: Drone 1, Drone 2, and Violin.
%
% This script follows the processing logic used in run_all_8_SQM.m and
% boxplotting.m:
%
%   1. Read the already-calculated PAZ/PAM/PAD MAT files.
%   2. Use only data whose original timestamps are within 2-12 s.
%   3. For each operating condition, align the 3 repeated recordings over
%      their common time interval and interpolate them onto one reference
%      time grid.
%   4. Average the 3 repeated curves point-by-point.
%   5. Calculate one condition-level Mean value from each averaged curve.
%   6. Within each sample category, compare PAZ/PAM/PAD across operating
%      conditions using condition-level Mean values.
%   7. Within each operating condition, compare the full instantaneous
%      three-repeat-averaged PAZ/PAM/PAD curves.
%
% Therefore:
%   Condition-level analysis:
%       Drone 1: n = 9 operating conditions
%       Drone 2: n = 9 operating conditions
%       Violin : n = 5 operating conditions
%
%   Within-condition instantaneous analysis:
%       One correlation matrix is calculated separately for each RPM/pitch.
%
% Outputs:
%   - Results are displayed in the MATLAB Command Window using disp().
%   - Heatmap figures are saved in SQMresults/model_correlations/.
%   - No CSV files are written.
%
% Heatmaps generated:
%   *_ConditionMean_Pearson_heatmap.png / .fig
%   *_ConditionMean_Spearman_heatmap.png / .fig
%   *_WithinCondition_Pearson_heatmaps.png / .fig
%   *_WithinCondition_Spearman_heatmaps.png / .fig

clc;
clear;
close all;

%% ========================= USER SETTINGS ===============================

plotTimeRange = [2, 12];

datasets = struct( ...
    'fieldName',   {'drone1', 'drone2', 'violin'}, ...
    'displayName', {'Drone 1', ...
                    'Drone 2', ...
                    'Violin'}, ...
    'resultRoot',  {fullfile('SQMresults', 'drone10802'), ...
                    fullfile('SQMresults', 'drone20814'), ...
                    fullfile('SQMresults', 'violin0804')}, ...
    'conditions',  {{'3428', '4455', '5816', '7119', '8397', ...
                     '9504', '10554', '11476', '12547'}, ...
                    {'2125', '3456', '4541', '5424', '6387', ...
                     '7213', '8467', '9423', '10377'}, ...
                    {'E3', 'Gsharp3', 'B3', 'C4', 'Csharp4'}}, ...
    'repetitions', {{'rpm01', 'rpm02', 'rpm03'}, ...
                    {'rpm01', 'rpm02', 'rpm03'}, ...
                    {'01', '02', '03'}});

% Three psychoacoustic-annoyance models saved by run_all_8_SQM.m.
models = struct( ...
    'name',      {'PA_{Zwicker}', 'PA_{More}', 'PA_{Di}'}, ...
    'suffix',    {'_PAZ.mat', '_PAM.mat', '_PAD.mat'}, ...
    'fieldName', {'InstantaneousPA', 'InstantaneousPA', 'InstantaneousPA'});

save_png = true;
save_fig = true;
image_resolution = 600;

outputDir = fullfile('SQMresults', 'model_correlations');

if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

%% ========================= MAIN ANALYSIS ================================

correlationResults = struct;

for datasetIndex = 1:numel(datasets)

    dataset = datasets(datasetIndex);

    nConditions = numel(dataset.conditions);
    nModels = numel(models);

    % Rows = operating conditions
    % Columns = PAZ, PAM, PAD
    conditionMeans = nan(nConditions, nModels);

    % Retain three-repeat-averaged time-varying curves.
    averagedTimes  = cell(nConditions, nModels);
    averagedCurves = cell(nConditions, nModels);

    fprintf('\n============================================================\n');
    fprintf('%s\n', upper(dataset.displayName));
    fprintf('============================================================\n');

    %% ---------- Obtain condition-level values for each model ------------

    for modelIndex = 1:nModels

        model = models(modelIndex);

        [meanTimes, meanCurves, meanValues] = ...
            averageRepeatedConditionCurves( ...
                dataset.resultRoot, ...
                dataset.conditions, ...
                dataset.repetitions, ...
                model.suffix, ...
                model.fieldName, ...
                plotTimeRange);

        conditionMeans(:, modelIndex) = meanValues;

        averagedTimes(:, modelIndex)  = meanTimes;
        averagedCurves(:, modelIndex) = meanCurves;
    end

    %% ============ 1) CONDITION-LEVEL MEAN CORRELATION ==================

    pearsonMean = corr(conditionMeans, ...
        'Type', 'Pearson', 'Rows', 'pairwise');

    spearmanMean = corr(conditionMeans, ...
        'Type', 'Spearman', 'Rows', 'pairwise');

    fprintf('\nCondition-level three-repeat-averaged MEAN values:\n');
    conditionTable = table( ...
        string(dataset.conditions(:)), ...
        conditionMeans(:,1), conditionMeans(:,2), conditionMeans(:,3), ...
        'VariableNames', {'Condition', 'PAZ_Mean', 'PAM_Mean', 'PAD_Mean'});
    disp(conditionTable);

    fprintf('\nCondition-level Pearson correlation matrix:\n');
    disp(array2table(pearsonMean, ...
        'VariableNames', {models.name}, ...
        'RowNames', {models.name}));

    fprintf('\nCondition-level Spearman correlation matrix:\n');
    disp(array2table(spearmanMean, ...
        'VariableNames', {models.name}, ...
        'RowNames', {models.name}));

    %% ============ 2) WITHIN-CONDITION INSTANTANEOUS CORRELATION ========

    withinPearson  = cell(nConditions, 1);
    withinSpearman = cell(nConditions, 1);

    fprintf('\nWithin-condition instantaneous correlations:\n');

    for conditionIndex = 1:nConditions

        % Align PAZ, PAM and PAD averaged curves onto a common model time grid.
        modelTimes  = averagedTimes(conditionIndex, :);
        modelCurves = averagedCurves(conditionIndex, :);

        commonStart = max(cellfun(@(x) x(1), modelTimes));
        commonEnd   = min(cellfun(@(x) x(end), modelTimes));

        [~, referenceModelIndex] = max(cellfun(@numel, modelTimes));
        referenceTime = modelTimes{referenceModelIndex};

        referenceTime = referenceTime( ...
            referenceTime >= commonStart & referenceTime <= commonEnd);

        assert(numel(referenceTime) >= 2, ...
            'No sufficient common model-time overlap for condition %s.', ...
            dataset.conditions{conditionIndex});

        alignedModelCurves = nan(numel(referenceTime), nModels);

        for modelIndex = 1:nModels
            [uniqueTime, uniqueIndices] = ...
                unique(modelTimes{modelIndex}, 'stable');

            uniqueCurve = modelCurves{modelIndex}(uniqueIndices);

            alignedModelCurves(:, modelIndex) = interp1( ...
                uniqueTime, uniqueCurve, referenceTime, 'linear');
        end

        withinPearson{conditionIndex} = corr( ...
            alignedModelCurves, ...
            'Type', 'Pearson', ...
            'Rows', 'pairwise');

        withinSpearman{conditionIndex} = corr( ...
            alignedModelCurves, ...
            'Type', 'Spearman', ...
            'Rows', 'pairwise');

        fprintf('\nCondition: %s\n', dataset.conditions{conditionIndex});

        fprintf('Pearson correlation matrix:\n');
        disp(array2table(withinPearson{conditionIndex}, ...
            'VariableNames', {models.name}, ...
            'RowNames', {models.name}));

        fprintf('Spearman correlation matrix:\n');
        disp(array2table(withinSpearman{conditionIndex}, ...
            'VariableNames', {models.name}, ...
            'RowNames', {models.name}));
    end

    %% ----------------------- Heatmap figures ----------------------------

    safeName = matlab.lang.makeValidName(dataset.fieldName);

    % One heatmap for the condition-level mean correlation.
    pearsonMeanFig = makeCorrelationHeatmap( ...
        pearsonMean, models, dataset.displayName, ...
        'Pearson', 'Condition-level mean');

    saveCorrelationFigure( ...
        pearsonMeanFig, ...
        fullfile(outputDir, [safeName '_ConditionMean_Pearson_heatmap']), ...
        save_png, save_fig, image_resolution);

    spearmanMeanFig = makeCorrelationHeatmap( ...
        spearmanMean, models, dataset.displayName, ...
        'Spearman', 'Condition-level mean');

    saveCorrelationFigure( ...
        spearmanMeanFig, ...
        fullfile(outputDir, [safeName '_ConditionMean_Spearman_heatmap']), ...
        save_png, save_fig, image_resolution);

    % Multi-panel heatmaps: one panel per RPM/pitch.
    pearsonWithinFig = makeWithinConditionHeatmaps( ...
        withinPearson, dataset.conditions, models, ...
        dataset.displayName, 'Pearson');

    saveCorrelationFigure( ...
        pearsonWithinFig, ...
        fullfile(outputDir, [safeName '_WithinCondition_Pearson_heatmaps']), ...
        save_png, save_fig, image_resolution);

    spearmanWithinFig = makeWithinConditionHeatmaps( ...
        withinSpearman, dataset.conditions, models, ...
        dataset.displayName, 'Spearman');

    saveCorrelationFigure( ...
        spearmanWithinFig, ...
        fullfile(outputDir, [safeName '_WithinCondition_Spearman_heatmaps']), ...
        save_png, save_fig, image_resolution);

    %% --------------------- Store processed results ----------------------

    correlationResults.(safeName).description = dataset.displayName;
    correlationResults.(safeName).conditions = dataset.conditions;
    correlationResults.(safeName).modelNames = {models.name};

    correlationResults.(safeName).conditionMeans = conditionMeans;
    correlationResults.(safeName).averagedTimes = averagedTimes;
    correlationResults.(safeName).averagedCurves = averagedCurves;

    correlationResults.(safeName).pearsonMean = pearsonMean;
    correlationResults.(safeName).spearmanMean = spearmanMean;

    correlationResults.(safeName).withinPearson = withinPearson;
    correlationResults.(safeName).withinSpearman = withinSpearman;
end

%% =========================== SAVE ALL ==================================

fprintf('\n============================================================\n');
fprintf('Correlation analysis completed.\n');
fprintf('Heatmap figures saved to: %s\n', outputDir);
fprintf('============================================================\n');


%% ========================= LOCAL FUNCTIONS =============================

function [meanTimes, meanCurves, meanValues] = ...
    averageRepeatedConditionCurves(resultRoot, conditions, repetitions, ...
                                   suffix, fieldName, timeRange)
%AVERAGEREPEATEDCONDITIONCURVES
% For each operating condition:
%   - read all repeated recordings,
%   - restrict them to the requested time range,
%   - determine their common temporal overlap,
%   - interpolate onto the longest repeat's time grid,
%   - average the repeated curves point-by-point,
%   - calculate the mean from that averaged curve.

    nConditions = numel(conditions);
    nSamples = numel(repetitions);

    meanTimes  = cell(nConditions, 1);
    meanCurves = cell(nConditions, 1);
    meanValues = nan(nConditions, 1);

    for conditionIndex = 1:nConditions

        conditionName = conditions{conditionIndex};

        repeatCurves = cell(nSamples, 1);
        repeatTimes  = cell(nSamples, 1);

        for sampleIndex = 1:nSamples

            repetition = repetitions{sampleIndex};

            filePath = fullfile( ...
                resultRoot, ...
                conditionName, ...
                [conditionName repetition suffix]);

            assert(isfile(filePath), ...
                'Result file not found: %s', filePath);

            loaded = load(filePath, 'OUT');

            assert(isfield(loaded, 'OUT'), ...
                'Variable OUT not found in %s', filePath);

            assert(isfield(loaded.OUT, fieldName), ...
                'Field OUT.%s not found in %s', fieldName, filePath);

            assert(isfield(loaded.OUT, 'time'), ...
                'Field OUT.time not found in %s', filePath);

            curveData = loaded.OUT.(fieldName);

            repeatCurves{sampleIndex} = curveData(:);
            repeatTimes{sampleIndex}  = loaded.OUT.time(:);

            assert(numel(repeatCurves{sampleIndex}) == ...
                   numel(repeatTimes{sampleIndex}), ...
                'OUT.%s and OUT.time have different lengths in %s', ...
                fieldName, filePath);

            assert(numel(repeatTimes{sampleIndex}) >= 2, ...
                'At least two time points are required in %s', filePath);

            % Apply 2-12 s again so that both old and newly trimmed result
            % files are handled consistently.
            timeMask = repeatTimes{sampleIndex} >= timeRange(1) & ...
                       repeatTimes{sampleIndex} <= timeRange(2);

            assert(nnz(timeMask) >= 2, ...
                'Fewer than two samples lie in %.3g-%.3g s in %s.', ...
                timeRange(1), timeRange(2), filePath);

            repeatTimes{sampleIndex} = ...
                repeatTimes{sampleIndex}(timeMask);

            repeatCurves{sampleIndex} = ...
                repeatCurves{sampleIndex}(timeMask);
        end

        % Use the longest repeat as the reference grid, but only inside
        % the common temporal overlap of all repeats.
        [~, referenceIndex] = max(cellfun(@numel, repeatTimes));

        referenceTime = repeatTimes{referenceIndex};

        commonStart = max(cellfun(@(x) x(1), repeatTimes));
        commonEnd   = min(cellfun(@(x) x(end), repeatTimes));

        referenceTime = referenceTime( ...
            referenceTime >= commonStart & referenceTime <= commonEnd);

        assert(numel(referenceTime) >= 2, ...
            'No sufficient common time overlap for condition %s.', ...
            conditionName);

        curveMatrix = nan(numel(referenceTime), nSamples);

        for sampleIndex = 1:nSamples

            [uniqueTime, uniqueIndices] = ...
                unique(repeatTimes{sampleIndex}, 'stable');

            uniqueCurve = ...
                repeatCurves{sampleIndex}(uniqueIndices);

            assert(numel(uniqueTime) >= 2, ...
                'Fewer than two unique time points in condition %s.', ...
                conditionName);

            curveMatrix(:, sampleIndex) = interp1( ...
                uniqueTime, ...
                uniqueCurve, ...
                referenceTime, ...
                'linear');
        end

        averagedCurve = mean(curveMatrix, 2, 'omitnan');

        meanTimes{conditionIndex}  = referenceTime;
        meanCurves{conditionIndex} = averagedCurve;

        meanValues(conditionIndex) = ...
            mean(averagedCurve, 'omitnan');
    end
end


function fig = makeCorrelationHeatmap( ...
    correlationMatrix, models, datasetName, correlationType, valueType)
%MAKECORRELATIONHEATMAP
% Draw a 3 x 3 correlation matrix for PAZ, PAM and PAD.
%
% The color scale is fixed to [-1, 1], allowing direct visual comparison
% among Drone 1, Drone 2 and Violin figures.
%
% Each cell is annotated with the corresponding correlation coefficient.

    modelNames = {models.name};

    fig = figure( ...
        'Color', 'w', ...
        'Name', sprintf('%s - %s %s correlation heatmap', ...
                        datasetName, correlationType, valueType), ...
        'NumberTitle', 'off', ...
        'Position', [100, 100, 650, 560]);

    ax = axes(fig);

    imagesc(ax, correlationMatrix, [-1 1]);
    axis(ax, 'square');

    % Diverging blue-white-red colormap centered at zero.
    nColors = 256;
    halfN = nColors / 2;

    blueToWhite = [ ...
        linspace(0.15, 1.00, halfN)', ...
        linspace(0.35, 1.00, halfN)', ...
        linspace(0.80, 1.00, halfN)'];

    whiteToRed = [ ...
        linspace(1.00, 0.80, halfN)', ...
        linspace(1.00, 0.20, halfN)', ...
        linspace(1.00, 0.15, halfN)'];

    colormap(ax, [blueToWhite; whiteToRed]);

    cb = colorbar(ax);
%     cb.Label.String = sprintf('%s correlation coefficient', correlationType);
%     cb.Label.FontSize = 13;
    cb.Ticks = -1:0.25:1;

    ax.XTick = 1:numel(modelNames);
    ax.YTick = 1:numel(modelNames);
    ax.XTickLabel = modelNames;
    ax.YTickLabel = modelNames;
    ax.FontSize = 18;
    ax.TickLength = [0 0];
    ax.Box = 'on';

%     xlabel(ax, 'Annoyance model', ...
%         'FontSize', 22, 'FontWeight', 'bold');
% 
%     ylabel(ax, 'Annoyance model', ...
%         'FontSize', 22, 'FontWeight', 'bold');

    title(ax, sprintf('%s', datasetName), ...
        'FontSize', 22, 'FontWeight', 'bold');

    % Add numeric values to every cell.
    for rowIndex = 1:size(correlationMatrix, 1)
        for columnIndex = 1:size(correlationMatrix, 2)

            value = correlationMatrix(rowIndex, columnIndex);

            if ~isfinite(value)
                labelText = 'NaN';
                textColor = 'k';
            else
                labelText = sprintf('%.2f', value);

                % White text on strongly colored cells; black near zero.
                if abs(value) >= 0.55
                    textColor = 'w';
                else
                    textColor = 'k';
                end
            end

            text(ax, columnIndex, rowIndex, labelText, ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'FontSize', 20, ...
                'FontWeight', 'bold', ...
                'Color', textColor);
        end
    end

    % Draw cell boundaries for a cleaner matrix appearance.
    hold(ax, 'on');

    n = size(correlationMatrix, 1);
    for boundary = 0.5:1:(n + 0.5)
        plot(ax, [0.5, n + 0.5], [boundary, boundary], ...
            'k-', 'LineWidth', 0.75);
        plot(ax, [boundary, boundary], [0.5, n + 0.5], ...
            'k-', 'LineWidth', 0.75);
    end

    hold(ax, 'off');

    xlim(ax, [0.5, n + 0.5]);
    ylim(ax, [0.5, n + 0.5]);
end


function fig = makeWithinConditionHeatmaps( ...
    correlationMatrices, conditions, models, datasetName, correlationType)
%MAKEWITHINCONDITIONHEATMAPS
% Draw one 3x3 correlation heatmap per operating condition.

    nConditions = numel(conditions);
    nCols = min(3, nConditions);
    nRows = ceil(nConditions / nCols);

    fig = figure( ...
        'Color', 'w', ...
        'Name', sprintf('%s - Within-condition %s correlations', ...
                        datasetName, correlationType), ...
        'NumberTitle', 'off', ...
        'Position', [50, 50, 1200, 350 * nRows]);

    layout = tiledlayout(fig, nRows, nCols, ...
        'TileSpacing', 'compact', ...
        'Padding', 'compact');

    modelNames = {models.name};

    for conditionIndex = 1:nConditions

        ax = nexttile(layout);
        matrixData = correlationMatrices{conditionIndex};

        imagesc(ax, matrixData, [-1 1]);
        axis(ax, 'square');

        nColors = 256;
        halfN = nColors / 2;

        blueToWhite = [ ...
            linspace(0.15, 1.00, halfN)', ...
            linspace(0.35, 1.00, halfN)', ...
            linspace(0.80, 1.00, halfN)'];

        whiteToRed = [ ...
            linspace(1.00, 0.80, halfN)', ...
            linspace(1.00, 0.20, halfN)', ...
            linspace(1.00, 0.15, halfN)'];

        colormap(ax, [blueToWhite; whiteToRed]);

        ax.XTick = 1:numel(modelNames);
        ax.YTick = 1:numel(modelNames);
        ax.XTickLabel = modelNames;
        ax.YTickLabel = modelNames;
        ax.FontSize = 11;
        ax.TickLength = [0 0];
        ax.Box = 'on';

        title(ax, conditions{conditionIndex}, ...
            'FontSize', 13, 'FontWeight', 'bold');

        for rowIndex = 1:size(matrixData, 1)
            for columnIndex = 1:size(matrixData, 2)

                value = matrixData(rowIndex, columnIndex);

                if ~isfinite(value)
                    labelText = 'NaN';
                    textColor = 'k';
                else
                    labelText = sprintf('%.3f', value);

                    if abs(value) >= 0.55
                        textColor = 'w';
                    else
                        textColor = 'k';
                    end
                end

                text(ax, columnIndex, rowIndex, labelText, ...
                    'HorizontalAlignment', 'center', ...
                    'VerticalAlignment', 'middle', ...
                    'FontSize', 11, ...
                    'FontWeight', 'bold', ...
                    'Color', textColor);
            end
        end

        hold(ax, 'on');

        n = size(matrixData, 1);
        for boundary = 0.5:1:(n + 0.5)
            plot(ax, [0.5, n + 0.5], [boundary, boundary], ...
                'k-', 'LineWidth', 0.5);
            plot(ax, [boundary, boundary], [0.5, n + 0.5], ...
                'k-', 'LineWidth', 0.5);
        end

        hold(ax, 'off');
        xlim(ax, [0.5, n + 0.5]);
        ylim(ax, [0.5, n + 0.5]);
    end

    title(layout, sprintf( ...
        '%s: Within-condition instantaneous %s correlations', ...
        datasetName, correlationType), ...
        'FontSize', 16, 'FontWeight', 'bold');

    cb = colorbar;
%     cb.Layout.Tile = 'east';
%     cb.Label.String = sprintf('%s correlation coefficient', correlationType);
    cb.Ticks = -1:0.25:1;
end


function saveCorrelationFigure( ...
    fig, basePath, savePng, saveFig, resolution)
%SAVECORRELATIONFIGURE Save PNG and/or MATLAB FIG.

    if savePng
        exportgraphics(fig, [basePath '.png'], ...
            'Resolution', resolution);
    end

    if saveFig
        savefig(fig, [basePath '.fig']);
    end
end
