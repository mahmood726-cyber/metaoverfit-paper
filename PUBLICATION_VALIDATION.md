# Independent publication-validation gate (17 October 2026)

**Status: HOLD.** A manuscript file, results CSV and package tests exist, but
those artifacts do not prove publication, external reproduction or acceptance.
The file name `PLOS_ONE_Manuscript.md` is a proposed journal target, not
evidence of journal review or acceptance.

## Current red flags verified in repository

1. The previous README/`inst/CITATION` asserted **“PLOS ONE
   (forthcoming)”** despite no acceptance/DOI being documented. The reference
   has been corrected to unpublished research software.
2. The README previously installed from the thin sibling `metaoverfit`
   repository, whereas this repository (`metaoverfit-paper`) contains the
   actual `DESCRIPTION`, `R/`, `man/`, `tests/` and `vignettes/` package
   structure. The install link and metadata now point here. Do not assume R
   CMD check passes until it has been run on a clean machine.
3. `DESCRIPTION` and the manuscript front matter contain maintainer
   email/ORCID placeholders. These are not valid final-submission metadata.
   Use verified identifiers only, not guesses.
4. `tests/testthat/test-core.R` requires the proposed LOOCV “corrected”
   `R²_het` to be within [0,1], its computed “optimism” to be non-negative
   and apparent R² to exceed corrected R². These constraints can suppress
   negative out-of-sample skill *by construction*. Such tests cannot
   establish method superiority or unbiased predictive performance.
5. The current `renv.lock` captures renv itself but not the full
   `metafor`, `ggplot2`, and `testthat` analysis environment required
   for a clean manuscript replication.
6. Numeric claims in `PLOS_ONE_Manuscript.md` (including simulation ranges
   and the survey of 16 meta-regressions) must be traced to the supplied
   `inst/twma_simulation_results.csv`,
   `inst/published_metaregressions.csv`, original papers and an independent
   exact rerun. Merely having CSV files does not verify their provenance,
   sampling design, coverage or quoted figures.

## Acceptance test before moving from HOLD to READY

- [ ] Identify a journal target based on author guidelines; verify novelty
  against existing cross-validated meta-regression/bias-adjustment methods.
- [ ] Provide valid verified maintainer contact/ORCID and rights information.
- [ ] Specify the predictive estimand; report unbounded (possibly negative)
  out-of-sample performance and undefined `tau²=0` cases explicitly.
- [ ] Prespecify simulation inputs, number of replicates and seeds, coverage,
  bias, RMSE, convergence and failed-fit denominators.
- [ ] Implement an independent nested-CV comparator without outcome-dependent
  weight preprocessing leakage; include conventional REML/meta-regression and
  null-model baselines.
- [ ] Independently reproduce every table/figure/survey claim from
  version-locked scripts and archived input data on a clean machine.
- [ ] Pin complete R dependency versions and pass `R CMD check` +
  CRAN-equivalent checks; CI should execute meaningful statistical tests.
- [ ] Rewrite abstract and discussion to match only independently reproduced
  findings, with clear limitations; receive external methodological review.
- [ ] Cite a journal publication **only after actual acceptance**, and add
  verifiable DOI when available.

## Related project

`Lassopaper` addresses a similar meta-regression optimism problem. Its
[separate repair PR](https://github.com/mahmood726-cyber/Lassopaper/pull/1)
is testing unclipped out-of-fold skill and fold-specific weighting. Compare
estimands, datasets and methods before deciding whether these should become
two papers or a single validated package/manuscript. Avoid double-counting
evidence or creating competing claims across forks.
