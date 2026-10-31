# Validation and known manuscript discrepancy

## Version and scope

The two supplied `revision2.pdf` files are byte-identical (SHA-256 `406ec7a4cf18c56e4293233a6c6369024beaa65e39e784bdb43da2591d361034`). The manuscript is dated 16 October 2026. Figure/table numbering was checked against its rendered pages and LaTeX source. Only Figures 5–16 and Tables I–VI are included.

## Figure checks

- Figures 5–7: extracted all 23 saved spectrograms directly from the MATLAB v7.3 results; checked matrix dimensions, 2–12 s time bounds, 0–4500 Hz frequency bounds and the linear-PSD-to-dB identity (absolute tolerance 1e-12).
- Figures 8–15: independently loaded all 69 recording-level curves for each of 8 metrics (552 input files). After common-grid alignment, each pointwise average matches the saved condition trajectory exactly at the checked precision: maximum absolute error 0.0. All 184 condition means and 95th percentiles pass numerical checks. Percentiles use the MATLAB-compatible Hazen convention.
- Figure 16: Pearson coefficients independently calculated from condition means match the stored heatmap matrices to at most 3.34e-16 absolute error. These are 9-condition, 9-condition and 5-condition correlations, respectively.
- All 12 figures were successfully redrawn using `scripts/replot.py`; representative spectral, boxplot and correlation outputs were visually checked against the manuscript. Replots are generated on demand and are not duplicated in the repository.

## Table checks and time-window mismatch

All **138 table entries** are preserved verbatim from the submitted LaTeX tables, including their two-decimal presentation. Their source excerpts are included alongside the CSV files. They are not recalculated replacements.

The supplied `dBdBA.m` sets `analysisTimeRange = [0, 15]`; its inline comment and the manuscript describe 2–12 s. The archived source is unchanged. Independent recalculations applied the same bilinear A-weighting filter to each complete recording before taking either the full-duration or the 2–12 s RMS level.

| Category | Number of recordings | Max absolute difference: original table LA vs full-duration calculation (dB) | Max absolute difference: table LZ−LA vs 0–15 s (dB) | Max absolute difference: table LZ−LA vs 2–12 s (dB) |
| --- | ---: | ---: | ---: | ---: |
| Drone 1 | 27 | 0.009072 | 0.005357 | 0.280648 |
| Drone 2 | 27 | 0.009092 | 0.005163 | 0.137598 |
| Violin | 15 | 0.009232 | 0.004717 | 0.103496 |

For Tables IV–VI, 66 of 69 full-duration recalculations round to the displayed table value, compared with 8 of 69 using 2–12 s. The other three full-duration differences are below 0.00536 dB; they are close to the rounding threshold but are not claimed to be exact matches. The data strongly support a full-recording origin for the submitted tables. The authors should reconcile the method description and tables in the manuscript before final publication. This repository does not decide whether to revise the text or recompute the tables.

Tables I–III differ from the independent full-duration LA recalculation by less than 0.01 dB. The original formatting/rounding procedure was not established, so these remain labeled as verbatim manuscript values, not numerically identical recomputations.

The individual results for both windows are in each table's `recalculation_audit.csv`. The original pressure files were used for these audits and are listed with hashes in `source_manifest.json`; they are not included in this plot-data package.

## Reproducibility boundaries

Saved numerical results are authoritative for this release. The package includes numerical replotting inputs and a Python plotting utility. The archived MATLAB scripts retain original paths and require the original pressure files or full SQAT outputs to run from raw signals. The SQAT library is not redistributed, and the psychoacoustic algorithms were not rerun from waveforms for this release.

No formal publication DOI, volume, issue, article number, open-data license or archive DOI has been invented. The author's confirmation of unpublished status takes precedence over a publication-list entry under 2026.
