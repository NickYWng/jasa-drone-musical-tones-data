# Original analysis methods

These MATLAB scripts are preserved unchanged for methodological provenance. They reference the original `recordings/` and `SQMresults/` input tree, which is not copied wholesale into this numerical plot-data release. SQAT is an external dependency. Use the exported CSV/NPZ/MAT plot data directly for replotting; these archived scripts are not a standalone raw-audio reproduction pipeline.

Important: `dBdBA.m` sets `analysisTimeRange = [0, 15]` despite a comment describing 2–12 s. The manuscript describes 2–12 s. Both windows were evaluated separately in the table audit; no source script or manuscript values were changed.
