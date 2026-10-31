# Figure 6: A-weighted spectrograms — Drone 2

Each condition has one compressed NumPy archive (`.npz`) and a gzip-compressed CSV spectral-level matrix. Values are extracted directly from the saved MATLAB spectral results, without recalculating or digitizing the image.

NPZ fields: `time_s` (original recording time, seconds), `frequency_Hz`, `PSD_Pa2_per_Hz` (linear A-weighted PSD), and `spectrum_dBA_per_Hz` (10 log10(PSD / (20 µPa)^2)). Matrix rows are frequencies and columns are times. CSV uses the same orientation, with frequencies in column 1 and time coordinates in the header. `conditions.csv` provides sampling rates and the blade-passing frequency and plotted band.

Three repeated recordings were averaged in the linear PSD domain. Processing: full-recording A-weighting, 30 ms symmetric Hann window, 75% overlap, next-power-of-two FFT; retain 2–12 s and 0–4500 Hz. Color range: 20–100 dBA/Hz. Reference processing script: `../methods/Aspectrogram_2.m`. These are processed plot data; pressure waveforms are outside this release.
