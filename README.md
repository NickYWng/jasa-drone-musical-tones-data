# Data for “Comparative Psychoacoustic Analysis of Drone Noise and Musical Tones”

Numerical data supporting **Figures 5–16 and Tables I–VI** of the manuscript. Figure directories are grouped under `figures/`, and table directories under `tables/`; each figure and table retains its own subdirectory. Figures 1–4 are excluded as requested.

## Manuscript information

- **Title:** Comparative Psychoacoustic Analysis of Drone Noise and Musical Tones
- **Authors:** Yinuo Wang and Xun Huang
- **Affiliation:** Department of Aeronautics and Astronautics, State Key Laboratory of Turbulence and Complex Systems, School of Mechanics and Engineering Science, Peking University, Beijing, China
- **Journal submitted to:** The Journal of the Acoustical Society of America (JASA)
- **Version represented:** manuscript PDF dated **16 October 2026**
- **Publication status:** **Not yet formally published**, as confirmed by the author on 31 October 2026. No publication DOI, volume, issue or page/article number has been assigned in this repository.

The [author's publication list](https://xunger99.github.io/xunger/papers.htm) lists the title under 2026; this is not used as evidence of formal publication. Update the citation when the publisher issues the final bibliographic record. The date above is the manuscript date, not a publication date.

Suggested manuscript citation:

> Wang, Y., and Huang, X. “Comparative Psychoacoustic Analysis of Drone Noise and Musical Tones.” Manuscript submitted to The Journal of the Acoustical Society of America, 16 October 2026. Not yet formally published.

Machine-readable references are provided in [citation.bib](citation.bib) and [CITATION.cff](CITATION.cff).

## Data availability

The numerical data underlying Figures 5–16 and Tables I–VI of the manuscript are contained in this repository. They include A-weighted spectrogram matrices, recording-level and condition-averaged psychoacoustic time histories, boxplot summaries, annoyance-model correlation matrices and their input means, and the tabulated sound-pressure levels. Each figure/table directory documents the variables, units and provenance. Figures 1–4 and the original pressure-waveform recordings are outside the scope of this release.

Repository: **https://github.com/NickYWng/jasa-drone-musical-tones-data**. The manuscript-ready statement, including this public repository URL, is in [DATA_AVAILABILITY.md](DATA_AVAILABILITY.md).

## Figure and table index

| Manuscript item | Directory | Numerical contents |
| --- | --- | --- |
| Figure 5 | [figure_05](figures/figure_05) | Drone 1: 9 averaged A-weighted spectrograms |
| Figure 6 | [figure_06](figures/figure_06) | Drone 2: 9 averaged A-weighted spectrograms |
| Figure 7 | [figure_07](figures/figure_07) | Violin: 5 averaged A-weighted spectrograms |
| Figure 8 | [figure_08](figures/figure_08) | Loudness, sone |
| Figure 9 | [figure_09](figures/figure_09) | Sharpness, acum |
| Figure 10 | [figure_10](figures/figure_10) | Roughness, asper |
| Figure 11 | [figure_11](figures/figure_11) | Tonality, t.u. |
| Figure 12 | [figure_12](figures/figure_12) | Fluctuation strength, vacil |
| Figure 13 | [figure_13](figures/figure_13) | Zwicker and Fastl annoyance (PAZ) |
| Figure 14 | [figure_14](figures/figure_14) | More annoyance (PAM) |
| Figure 15 | [figure_15](figures/figure_15) | Di et al. annoyance (PAD) |
| Figure 16 | [figure_16](figures/figure_16) | Three condition-level Pearson matrices and their input means |
| Table I | [table_01](tables/table_01) | Original A-weighted OASPL, Drone 1 |
| Table II | [table_02](tables/table_02) | Original A-weighted OASPL, Drone 2 |
| Table III | [table_03](tables/table_03) | Original A-weighted OASPL, violin |
| Table IV | [table_04](tables/table_04) | Normalized recordings: LZ − LA, Drone 1 |
| Table V | [table_05](tables/table_05) | Normalized recordings: LZ − LA, Drone 2 |
| Table VI | [table_06](tables/table_06) | Normalized recordings: LZ − LA, violin |

The machine-readable index is [figure_table_index.csv](figure_table_index.csv).

## Experimental conditions and interpretation

There are 69 recordings: 9 rotational speeds × 3 recordings for each of two isolated three-blade propellers, and 5 app-generated sustained violin pitches × 3 recordings. Drone 1 uses the nominal 5-inch-class Qianfeng 5129 propeller; Drone 2 uses the 7-inch HQProp HQ 7040 propeller. Violin labels are E3, G#3, B3, C4 and C#4; filenames spell sharps as `Gsharp3` and `Csharp4`.

The input recordings were normalized to 75 dB(A). Figure data use the original 2–12 s timestamps. Spectrograms average the three recordings in the **linear PSD domain** before conversion to dB. Boxplots describe the temporal distribution of the **pointwise average of three instantaneous trajectories**. Their observations are time samples, not independent recording replicates. Figure 16 correlates condition means, with 9, 9 and 5 observations for Drone 1, Drone 2 and violin respectively.

**Table-method discrepancy:** The manuscript describes 2–12 s for the level-difference calculation, while the supplied `dBdBA.m` selects 0–15 s. The submitted Tables IV–VI are much closer to the 0–15 s recalculation. Their manuscript values are preserved unchanged. Both recalculations and their differences are supplied separately. See [VALIDATION.md](VALIDATION.md) before interpreting or reproducing these tables.

## File formats and reading the data

- `.csv`: UTF-8 comma-separated text with column headers.
- `.csv.gz`: gzip-compressed CSV; no precision reduction is applied to numerical values.
- `.npz`: compressed NumPy arrays for spectra. Arrays are frequency-by-time; axes and linear PSD are included.
- `.mat`: MATLAB-compatible per-figure cached plot data for Figures 8–15.
- `.jpg`: the corresponding submitted figure, provided for visual identification.
- `.m`: unchanged original method scripts in [methods](methods), with their original input paths.

Example in Python:

```python
import csv, gzip
import numpy as np

data = np.load("figures/figure_05/3428_spectrogram.npz")
time_s = data["time_s"]
frequency_Hz = data["frequency_Hz"]
level = data["spectrum_dBA_per_Hz"]  # shape: frequency × time

with gzip.open("figures/figure_08/drone1_trajectories.csv.gz", "rt", newline="") as f:
    rows = list(csv.DictReader(f))
```

Run `python scripts/replot.py --output reproduced_figures` to recreate the numerical plots using Python, NumPy and Matplotlib. This reproduces data content; the typography need not match the manuscript. MATLAB users can load `figures/figure_08/plot_data.mat` (and the equivalent files in Figures 9–15) directly. Gzip CSV files can also be decompressed with standard archive software.

The original MATLAB methods depend on the original input tree and, for psychoacoustic calculations, the external Sound Quality Analysis Toolbox (SQAT). This package is a **numerical figure/table dataset**, not a full raw-recording or SQAT distribution. Source waveforms were used locally to audit tables and are not bundled. See [methods/README.md](methods/README.md).

## Provenance and validation

[source_manifest.json](source_manifest.json) records source-relative paths, SHA-256 hashes and extraction roles. [validation_results.json](validation_results.json) records numerical checks. [SHA256SUMS](SHA256SUMS) checks the released files. No values were digitized from raster figures, and manuscript table values were not silently replaced by recalculations.

No reuse license has been selected by the authors for this prepared package. Public access alone does not establish an unrestricted reuse license. Citation and reuse terms can be updated with the final publication record.
