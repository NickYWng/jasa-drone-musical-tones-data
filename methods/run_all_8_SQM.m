% RUN_ALL_8_SQM
% Compute and save eight sound-quality metrics for two drones and violin.
%
% Datasets:
%   drone10802 : 9 RPM conditions x 3 recordings
%   drone20814 : 9 RPM conditions x 3 recordings
%   violin0804 : 5 pitch conditions x 3 recordings
%
% Metrics and output suffixes:
%   Loudness                    _N.mat
%   Sharpness                   _S.mat
%   Roughness                   _R.mat
%   Tonality                    _K.mat
%   Fluctuation strength        _FS.mat
%   Widmann annoyance (PAZ)     _PAZ.mat
%   More annoyance (PAM)        _PAM.mat
%   Di annoyance (PAD)          _PAD.mat

clc;
clear;
close all;

field = 0;
time_skip = 0.5;

% Calculate every metric from the complete recording, but only save the
% time-varying results whose original timestamps are between 2 and 12 s.
save_time_range = [2, 12];

datasets = struct( ...
    'name', {'drone10802', 'drone20814', 'violin0804'}, ...
    'conditions', { ...
        {'3428', '4455', '5816', '7119', '8397', '9504', '10554', '11476', '12547'}, ...
        {'2125', '3456', '4541', '5424', '6387', '7213', '8467', '9423', '10377'}, ...
        {'E3', 'Gsharp3', 'B3', 'C4', 'Csharp4'}}, ...
    'repetitions', { ...
        {'rpm01', 'rpm02', 'rpm03'}, ...
        {'rpm01', 'rpm02', 'rpm03'}, ...
        {'01', '02', '03'}});

for d = 1:numel(datasets)
    dataset = datasets(d);
    input_root = fullfile('recordings', dataset.name, '75A_mat');
    output_root = fullfile('SQMresults', dataset.name);

    fprintf('\n=== Processing %s ===\n', dataset.name);

    for i = 1:numel(dataset.conditions)
        condition = dataset.conditions{i};
        output_dir = fullfile(output_root, condition);
        if ~exist(output_dir, 'dir')
            mkdir(output_dir);
        end

        for j = 1:numel(dataset.repetitions)
            repetition = dataset.repetitions{j};
            sample_name = [condition repetition];
            input_file = fullfile(input_root, [sample_name '_75.mat']);

            assert(exist(input_file, 'file') == 2, ...
                'Input file not found: %s', input_file);

            input_data = load(input_file);
            assert(isfield(input_data, 'p_data_adjusted'), ...
                'Variable p_data_adjusted is missing from %s.', input_file);
            assert(isfield(input_data, 'fs'), ...
                'Variable fs is missing from %s.', input_file);

            signal = input_data.p_data_adjusted;
            fs = input_data.fs;

            fprintf('Processing %-20s', sample_name);

            % 1. Loudness (ISO 532-1), time-varying method
            OUT = Loudness_ISO532_1(signal, fs, field, 2, time_skip, 0);
            OUT = trim_metric_output(OUT, save_time_range);
            save(fullfile(output_dir, [sample_name '_N.mat']), 'OUT');
            fprintf(' N');

            % 2. Sharpness (DIN 45692), based on time-varying loudness
            OUT = Sharpness_DIN45692( ...
                signal, fs, 'DIN45692', field, 2, time_skip, 0, 0);
            OUT = trim_metric_output(OUT, save_time_range);
            save(fullfile(output_dir, [sample_name '_S.mat']), 'OUT');
            fprintf(' S');

            % 3. Roughness (Daniel and Weber, 1997)
            OUT = Roughness_Daniel1997(signal, fs, time_skip, 0);
            OUT = trim_metric_output(OUT, save_time_range);
            save(fullfile(output_dir, [sample_name '_R.mat']), 'OUT');
            fprintf(' R');

            % 4. Tonality (Aures, 1985)
            OUT = Tonality_Aures1985(signal, fs, 1, time_skip, 0);
            OUT = trim_metric_output(OUT, save_time_range);
            save(fullfile(output_dir, [sample_name '_K.mat']), 'OUT');
            fprintf(' K');

            % 5. Fluctuation strength (Osses, 2016)
            OUT = FluctuationStrength_Osses2016( ...
                signal, fs, 1, time_skip, 0);
            OUT = trim_metric_output(OUT, save_time_range);
            save(fullfile(output_dir, [sample_name '_FS.mat']), 'OUT');
            fprintf(' FS');

            % 6. Psychoacoustic annoyance: Widmann (PAZ)
            OUT = PsychoacousticAnnoyance_Widmann1992( ...
                signal, fs, field, time_skip, 0, 0);
            OUT = trim_metric_output(OUT, save_time_range);
            save(fullfile(output_dir, [sample_name '_PAZ.mat']), 'OUT');
            fprintf(' PAZ');

            % 7. Psychoacoustic annoyance: More (PAM)
            OUT = PsychoacousticAnnoyance_More2010( ...
                signal, fs, field, time_skip, 0, 0);
            OUT = trim_metric_output(OUT, save_time_range);
            save(fullfile(output_dir, [sample_name '_PAM.mat']), 'OUT');
            fprintf(' PAM');

            % 8. Psychoacoustic annoyance: Di (PAD)
            OUT = PsychoacousticAnnoyance_Di2016( ...
                signal, fs, field, time_skip, 0, 0);
            OUT = trim_metric_output(OUT, save_time_range);
            save(fullfile(output_dir, [sample_name '_PAD.mat']), 'OUT');
            fprintf(' PAD\n');
        end
    end
end

fprintf('\nAll eight SQMs have been calculated and saved.\n');


function S = trim_metric_output(S, time_range)
%TRIM_METRIC_OUTPUT Recursively retain timestamped data in [t1, t2].
% The metric is calculated before this function is called, so filter memory
% and analysis windows still have access to the complete input recording.

    if ~isstruct(S)
        return;
    end

    % PA outputs contain nested L, S, R and FS structures. Trim them too.
    names = fieldnames(S);
    for k = 1:numel(names)
        name = names{k};
        if isstruct(S.(name))
            S.(name) = trim_metric_output(S.(name), time_range);
        end
    end

    if ~isfield(S, 'time') || ~isnumeric(S.time) || ~isvector(S.time)
        return;
    end

    old_time = S.time;
    keep = old_time >= time_range(1) & old_time <= time_range(2);
    n_time = numel(old_time);

    if ~any(keep)
        warning('No samples found between %.3f and %.3f s.', ...
            time_range(1), time_range(2));
        return;
    end

    % Trim every array whose row or column count matches this time vector.
    names = fieldnames(S);
    for k = 1:numel(names)
        name = names{k};
        value = S.(name);

        if isstruct(value) || ~(isnumeric(value) || islogical(value) || iscell(value))
            continue;
        end

        if isvector(value) && numel(value) == n_time
            S.(name) = value(keep);
        elseif ~isvector(value) && size(value, 1) == n_time
            S.(name) = value(keep, :);
        elseif ~isvector(value) && size(value, 2) == n_time
            S.(name) = value(:, keep);
        end
    end

    % Loudness stores InstantaneousSPL on a different sampling grid from
    % OUT.time. Trim it using its own uniformly spaced time grid.
    if isfield(S, 'InstantaneousSPL') && isnumeric(S.InstantaneousSPL) && ...
            isfield(S, 'time_insig') && isnumeric(S.time_insig) && ...
            isvector(S.time_insig)
        n_spl = numel(S.InstantaneousSPL);
        spl_time = linspace(S.time_insig(1), S.time_insig(end), n_spl);
        keep_spl = spl_time >= time_range(1) & spl_time <= time_range(2);
        S.InstantaneousSPL = S.InstantaneousSPL(keep_spl);
        S.InstantaneousSPL_time = spl_time(keep_spl);
    end

    % Some loudness outputs also contain the input-signal time vector.
    if isfield(S, 'time_insig') && isnumeric(S.time_insig) && ...
            isvector(S.time_insig)
        keep_input_time = S.time_insig >= time_range(1) & ...
                          S.time_insig <= time_range(2);
        S.time_insig = S.time_insig(keep_input_time);
    end

    S.saved_time_range = time_range;
end
