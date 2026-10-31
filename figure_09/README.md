# Figure 9: Sharpness

Units: **acum**. Each `*_trajectories.csv.gz` contains the three recording-level instantaneous trajectories, aligned to the saved common time grid, and their pointwise mean. Columns: `condition`, `time_s`, `repeat_1`, `repeat_2`, `repeat_3`, `condition_mean`. All times are original recording timestamps within 2–12 s. Conditions are RPM for drones; `Gsharp3` = G#3 and `Csharp4` = C#4.

The boxplots describe temporal variation of the **pointwise mean of three recordings**, not the distribution of three recording means. `summary.csv` gives the number of time points, mean, quartiles, median, 95th percentile (5% exceedance value), minimum and maximum of each averaged trajectory. Mean and p95 were preserved from the saved MATLAB results; quartiles use MATLAB-compatible (Hazen) percentile interpolation. The source plotting script specifies a whisker factor of 10 IQR.

`plot_data.mat` contains this figure's saved MATLAB `plotData` struct, with category-specific `labels`, `time`, `curves`, `mean`, and `p95`. All 69 recording-level curves were checked against the saved 23 condition averages. Reference script: `../methods/boxplotting.m` (original input paths retained).
