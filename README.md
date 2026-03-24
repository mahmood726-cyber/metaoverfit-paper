# metaoverfit

**metaoverfit** detects and corrects overfitting in meta-regression. When the number of studies (*k*) is small relative to the number of moderators (*p*), apparent R-squared heterogeneity values can be spuriously inflated. This package implements leave-one-out cross-validation (LOOCV) and non-parametric bootstrap procedures to quantify and correct this optimism.

## Installation

Install the development version from GitHub:

```r
# install.packages("remotes")
remotes::install_github("mahmood726-cyber/metaoverfit")
```

## Features

- **Apparent and LOOCV-corrected R2het** -- `r2het_cv()` computes a cross-validated estimate that shrinks the apparent R2het toward its predictive value.
- **Bootstrap confidence intervals** -- `r2het_boot()` generates percentile CIs and diagnoses boundary effects (tau-squared = 0 hits).
- **One-line overfitting audit** -- `check_overfitting()` wraps CV + bootstrap into a single call with a formatted print method.
- **Sample size guidance** -- `sample_size_recommendation()` implements the "rule of 10" heuristic (*k/p >= 10*).
- **Diagnostic plots** -- `plot_overfitting()` visualises apparent vs. corrected R2het (bar chart or bootstrap histogram).

## Quick Start

```r
library(metaoverfit)
library(metadat)
library(metafor)

# Load BCG vaccine dataset (k = 13)
data(dat.bcg)
dat <- escalc(measure = "RR", ai = tpos, bi = tneg,
              ci = cpos, di = cneg, data = dat.bcg)

# Full overfitting check
res <- check_overfitting(yi = yi, vi = vi, mods = ~ablat,
                         data = dat, B = 1000)
print(res)
# => Apparent R2het vs. LOOCV-corrected, bootstrap CI, k/p warning

# Plot
plot_overfitting(res, type = "bar")
plot_overfitting(res, type = "histogram")
```

## Example Output

```
Meta-Regression Overfitting Audit
==================================
Studies (k): 13 | Moderators (p): 1 | k/p ratio: 13.0
Apparent R2_het:    0.646
LOOCV R2_het:       0.437
Estimated optimism: 0.209
95% Bootstrap CI:  [0.042, 1.000]  (B = 1000)
Boundary hits:      28 / 1000 (2.8%)

** WARNING: k/p ratio < 10. Model stability is questionable.
```

## Dependencies

- [metafor](https://cran.r-project.org/package=metafor) (>= 3.0.0)
- [ggplot2](https://cran.r-project.org/package=ggplot2)
- [parallel](https://stat.ethz.ch/R-manual/R-devel/library/parallel/html/parallel-package.html) (base R)

## Citation

If you use **metaoverfit** in a publication, please cite:

> Ahmad M (2026). metaoverfit: An R Package for Detecting and Correcting Overfitting in Meta-Regression. *PLOS ONE* (forthcoming).

## License

GPL-3

## Bug Reports and Contributions

Please submit issues or pull requests on [GitHub](https://github.com/mahmood726-cyber/metaoverfit/issues).
