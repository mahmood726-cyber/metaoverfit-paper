# metaoverfit

**metaoverfit** is a research-stage R package for exploring potential overfitting in meta-regression. Its proposed correction requires independent validation. When the number of studies (*k*) is small relative to the number of moderators (*p*), apparent R-squared heterogeneity values can be spuriously inflated. This package implements leave-one-out cross-validation (LOOCV) and non-parametric bootstrap procedures to quantify and correct this optimism.

## Installation

Install the development version from GitHub:

```r
# install.packages("remotes")
remotes::install_github("mahmood726-cyber/metaoverfit-paper")
```

## Features

- **Apparent and internally validated R2het** -- `r2het_cv()` reports exploratory apparent and leave-one-out summaries. A bounded result is not equivalent to independently established predictive skill.
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

## Example output and reproducibility

The numerical output depends on input data and exact dependency versions.
Do **not** treat any illustrative result as a reproduced empirical benchmark.
The paper's claimed simulation and external-data results require independent
rerunning and data-provenance review before publication. See
[Publication validation gates](PUBLICATION_VALIDATION.md).

## Dependencies

- [metafor](https://cran.r-project.org/package=metafor) (>= 3.0.0)
- [ggplot2](https://cran.r-project.org/package=ggplot2)
- [parallel](https://stat.ethz.ch/R-manual/R-devel/library/parallel/html/parallel-package.html) (base R)

## Citation

The methods manuscript in this repository is a **draft**. No verified journal acceptance or DOI is provided here. Until one is established, cite the software repository and commit/release version, not an unverified journal publication.

## License

GPL-3

## Bug Reports and Contributions

Please submit issues or pull requests on [GitHub](https://github.com/mahmood726-cyber/metaoverfit-paper/issues).

**Release hold:** not independently validated for paper submission; see [PUBLICATION_VALIDATION.md](PUBLICATION_VALIDATION.md).
