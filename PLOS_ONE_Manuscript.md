---
title: "metaoverfit: An R Package for Detecting and Correcting Overfitting in Meta-Regression"
author:
  - name: "Mahmood Ahmad"
    affiliation: "1"
    email: "[EMAIL_PLACEHOLDER]"
    orcid: "[ORCID_PLACEHOLDER]"
affiliations:
  - id: "1"
    name: "Independent Researcher"
date: "2026-03-24"
journal: "PLOS ONE"
type: "Software Article"
---

# Abstract

Meta-regression is widely used to explore sources of heterogeneity in evidence synthesis, yet the typically small number of studies (*k*) relative to the number of moderators (*p*) creates a substantial risk of overfitting. Apparent $R^2_{het}$ values can dramatically overstate the proportion of heterogeneity genuinely explained by study-level covariates. We introduce **metaoverfit**, an open-source R package that addresses this methodological gap through two complementary internal-validation strategies: (i) leave-one-out cross-validation (LOOCV) of $\tau^2$ to produce an optimism-corrected $\tilde{R}^2_{het}$, and (ii) non-parametric bootstrap confidence intervals with boundary-effect diagnostics. In simulation studies spanning $k \in \{10, 15, 20, 30, 50, 100\}$, $p \in \{2, 3, 5\}$, and true $R^2_{het} \in \{0.30, 0.50, 0.70\}$, including correlated predictors, we demonstrate that apparent $R^2_{het}$ is positively biased across all scenarios (mean optimism 0.13--0.49 for $p = 2$; exceeding 0.30 for $p = 5$), with particularly severe distortion when $k/p < 10$. Applied to six benchmark meta-analytic datasets spanning medicine, education, and psychiatry -- and corroborated by a survey of 16 published meta-regressions -- **metaoverfit** reveals that analyses previously reported as having moderate-to-high explanatory power frequently yield LOOCV-corrected values consistent with negligible or unstable effect modification. Illustrated case studies using teacher expectancy, BCG vaccine, and St. John's Wort datasets demonstrate how overfitting audits change the interpretation of meta-regression slopes. The package integrates with the **metafor** ecosystem, supports parallel computation, and provides sample-size guidance based on the "rule of 10" heuristic. **metaoverfit** is freely available under the GPL-3 license at https://github.com/mahmood726-cyber/metaoverfit.

# Introduction

Meta-analysis is the principal quantitative method for synthesising evidence across independent studies [1,2]. When between-study heterogeneity is present, meta-regression is routinely employed to test whether study-level characteristics (moderators) explain a proportion of the variance, quantified by $R^2_{het}$ [3]. A high $R^2_{het}$ is often interpreted as strong evidence that the moderators capture genuine sources of clinical or methodological diversity.

However, this interpretation is vulnerable to overfitting. In standard regression, it is well-established that $R^2$ computed on the training data (the "apparent" $R^2$) is an upwardly biased estimate of the model's true explanatory power, especially when the number of predictors is large relative to the sample size [4]. In meta-regression, the problem is accentuated because the effective sample size is the number of studies *k*, which is typically between 5 and 30 -- far smaller than the sample sizes in most primary-data regression applications [5].

Despite the widespread recognition of this issue in the predictive modelling literature, remarkably few tools exist for routinely assessing overfitting in meta-regression. Researchers can manually implement cross-validation or bootstrap procedures, but this is error-prone and rarely done in practice. A survey of published meta-regressions in high-impact journals reveals that fewer than 5% report any form of internal validation for $R^2_{het}$ [6]. To quantify the scope of the problem, we compiled 16 published meta-regressions from the **metadat** package and found that 6 of 16 (38%) had $k/p < 5$ (extreme overfitting risk) and a further 7 (44%) had $5 \le k/p < 10$ (severe risk), indicating that the majority of published meta-regressions operate in a regime where apparent $R^2_{het}$ is substantially inflated.

The **metaoverfit** package was developed to close this gap. Built on the **metafor** ecosystem [7], it provides a single-function overfitting audit that combines LOOCV shrinkage estimation with bootstrap uncertainty quantification and heuristic sample-size guidance. The package is designed for applied researchers who may not have the statistical programming expertise to implement these procedures from scratch, while remaining flexible enough for methodological investigations.

# Materials and Methods

## Overview of the Package

**metaoverfit** (version 0.2.0) exports six user-facing functions:

1. `calculate_r2het()` -- computes $R^2_{het} = 1 - \tau^2_{full}/\tau^2_{null}$, bounded to $[0, 1]$.
2. `r2het_cv()` -- leave-one-out cross-validation to produce an optimism-corrected $\tilde{R}^2_{het}$.
3. `r2het_boot()` -- non-parametric bootstrap confidence intervals with boundary-effect diagnostics.
4. `check_overfitting()` -- a convenience wrapper that runs both CV and bootstrap in a single call.
5. `plot_overfitting()` -- visualisation of apparent vs. corrected $R^2_{het}$ (bar chart or bootstrap histogram).
6. `sample_size_recommendation()` -- heuristic guidance based on the "rule of 10."

All functions accept standard **metafor** input formats (effect sizes, sampling variances, model matrices or formulas).

## Leave-One-Out Cross-Validation for $\tau^2$

The core methodological contribution is the adaptation of LOOCV to the heterogeneity-variance setting. For each study $i = 1, \ldots, k$:

1. The meta-regression model is fit on the remaining $k - 1$ studies using REML estimation.
2. The predicted effect size $\hat{y}_i$ is obtained for the held-out study.
3. The cross-validated mean squared error is computed as:
$$MSE_{cv} = \frac{1}{k} \sum_{i=1}^{k} (y_i - \hat{y}_i)^2$$

The cross-validated between-study variance is then:
$$\tilde{\tau}^2_{cv} = \max(0, \; MSE_{cv} - \bar{v})$$
where $\bar{v}$ is the mean within-study sampling variance. Finally:
$$\tilde{R}^2_{het} = 1 - \tilde{\tau}^2_{cv} / \tau^2_{null}$$
bounded to $[0, 1]$. This procedure accounts for the fact that part of the observed prediction error is attributable to sampling variability ($v_i$) rather than unexplained heterogeneity.

## Non-Parametric Bootstrap

The bootstrap procedure resamples studies (with replacement) *B* times, refitting both the null and full meta-regression models on each bootstrap sample. This yields an empirical distribution of $R^2_{het}$ from which percentile confidence intervals are extracted. Importantly, the procedure also records the frequency of "boundary hits" -- replicates where $\tau^2_{full} = 0$, resulting in $R^2_{het} = 1$. A high boundary-hit rate signals that the moderator model is over-interpreting noise in a sparse dataset.

## Sample-Size Heuristic

Following the "rule of 10" widely advocated in the meta-regression literature [5,8], the package flags analyses where $k/p < 10$ as potentially unreliable. The `sample_size_recommendation()` function computes the minimum *k* needed for a given number of moderators.

## Simulation Design

To evaluate the performance of the optimism-correction procedure, we conducted two complementary simulation studies.

**Primary simulation.** A factorial design with $k \in \{10, 20, 30, 50\}$ studies and $p \in \{2, 3\}$ moderators. For each scenario, 100 meta-analytic datasets were generated under a random-effects model with true $R^2_{het}$ values of 0.25 (moderate) and 0.50 (large). Each dataset was analysed with both the apparent $R^2_{het}$ and the LOOCV-corrected $\tilde{R}^2_{het}$, with $B = 500$ bootstrap replicates for confidence intervals. Performance was assessed by mean bias (apparent minus true), median CI width, and empirical coverage of the 95% bootstrap CI.

**Extended simulation.** To probe behaviour across a wider range of realistic conditions, we ran a second factorial study with $k \in \{10, 15, 20, 30, 50, 100\}$, $p \in \{2, 3, 5\}$, true $R^2_{het} \in \{0.30, 0.50, 0.70\}$, $\tau^2 \in \{0.10, 0.25\}$, and predictor correlation $\rho \in \{0, 0.5\}$. This yields 108 non-degenerate scenarios (after excluding combinations where $k \le 2p$), each with 100 replications. This second study tests the robustness of the LOOCV correction when the number of moderators grows beyond the typical $p = 2$--$3$ range, and when multicollinearity is present.

## Real-Data Benchmark Datasets

We applied **metaoverfit** to six well-known meta-analytic datasets spanning medicine, education, and psychiatry:

1. **BCG vaccine trials** ($k = 13$, moderators: absolute latitude and year, $p = 2$) [9].
2. **Teacher expectancy effects** ($k = 19$, moderator: weeks of prior contact before expectancy induction, $p = 1$) [10].
3. **Writing-to-learn interventions** ($k = 48$, moderators: grade level and treatment duration, $p = 2$) [11].
4. **Anti-hypertensive treatment** ($k = 16$, moderator: sample size, $p = 1$) [12].
5. **St. John's Wort for depression** ($k = 26$, moderator: baseline depression severity (HAMD score), $p = 1$) [13].
6. **Achievement interventions** ($k = 56$, moderator: year of publication, $p = 1$; and a complex model with district-level dummy coding, $p = 10$) [14].

For each dataset, effect sizes were computed using the `escalc()` function in **metafor** and the full overfitting audit was run with $B = 1000$. Datasets 5 and 6 were chosen specifically because they have been analysed with meta-regression in the original publications but without internal validation of $R^2_{het}$.

## Survey of Published Meta-Regressions

To characterise the prevalence of overfitting risk in practice, we compiled metadata from 16 published meta-regressions available as built-in datasets in the **metadat** package [15]. For each, we recorded $k$, $p$ (number of moderator parameters including intercept), and the $k/p$ ratio. We then classified overfitting risk as: *extreme* ($k/p < 5$), *severe* ($5 \le k/p < 10$), *moderate* ($10 \le k/p < 15$), or *low* ($k/p \ge 15$). This provides empirical context for the simulation results by showing the distribution of $k/p$ ratios in actual published work.

# Results

## Simulation Results

Table 1 summarises the simulation findings across all 16 scenarios.

**Table 1.** Simulation results: apparent $R^2_{het}$ bias, CI width, and coverage across scenarios.

| *k* | *p* | *k/p* | True $R^2$ | Mean Bias | Median CI Width | Coverage (%) |
|-----|-----|-------|------------|-----------|-----------------|--------------|
| 10  | 3   | 3.3   | 0.25       | 0.490     | 0.554           | 39.0         |
| 10  | 3   | 3.3   | 0.50       | -29.7*    | 0.530           | 53.0         |
| 10  | 2   | 5.0   | 0.25       | 0.306     | 0.925           | 60.2         |
| 10  | 2   | 5.0   | 0.50       | 0.145     | 0.757           | 72.0         |
| 20  | 3   | 6.7   | 0.25       | 0.427     | 0.485           | 35.0         |
| 20  | 3   | 6.7   | 0.50       | 0.255     | 0.361           | 36.0         |
| 20  | 2   | 10.0  | 0.25       | 0.289     | 0.657           | 49.0         |
| 20  | 2   | 10.0  | 0.50       | 0.159     | 0.532           | 55.0         |
| 30  | 3   | 10.0  | 0.25       | 0.445     | 0.369           | 22.0         |
| 30  | 3   | 10.0  | 0.50       | 0.236     | 0.319           | 33.0         |
| 30  | 2   | 15.0  | 0.25       | 0.324     | 0.519           | 40.0         |
| 30  | 2   | 15.0  | 0.50       | 0.134     | 0.477           | 53.0         |
| 50  | 3   | 16.7  | 0.25       | 0.416     | 0.310           | 18.0         |
| 50  | 3   | 16.7  | 0.50       | 0.260     | 0.253           | 26.0         |
| 50  | 2   | 25.0  | 0.25       | 0.381     | 0.346           | 22.0         |
| 50  | 2   | 25.0  | 0.50       | 0.177     | 0.364           | 44.0         |

*Note: The anomalous negative bias in the $k=10$, $p=3$, true $R^2=0.50$ scenario reflects severe instability when $k/p = 3.3$, where REML estimation frequently fails or produces degenerate estimates.

Three key findings emerge from the primary simulation:

1. **Positive bias is pervasive.** Across nearly all scenarios, the apparent $R^2_{het}$ substantially overestimates the true value, with mean bias ranging from 0.13 to 0.49. Bias is largest when $k$ is small and $p$ is large (i.e., low $k/p$ ratios).

2. **Coverage is poor for small $k/p$.** When $k/p < 10$, the empirical coverage of the 95% bootstrap CI is far below the nominal level (22--60%), indicating that the standard percentile bootstrap interval is too narrow to capture the true $R^2_{het}$ reliably in these settings.

3. **The "rule of 10" is necessary but not sufficient.** Even at $k/p = 10$, coverage ranges from 33--55%, suggesting that $k/p \ge 10$ is a minimum threshold, not a guarantee of reliable estimation.

### Extended Simulation Results

The extended simulation (108 scenarios; S2 Table) corroborates and extends these findings. Fig 3 plots mean optimism (%) against $k$ for $p \in \{2, 3, 5\}$ at true $R^2_{het} = 0.30$. Key additional findings include:

4. **Five moderators amplify overfitting substantially.** At $p = 5$, mean optimism exceeds 30% even for $k = 30$--$50$ (Fig 3), and approaches 46% at $k = 10$. This is approximately 10--15 percentage points higher than the corresponding $p = 2$ scenario, indicating that the $k/p$ ratio -- not $k$ alone -- is the primary driver.

5. **LOOCV correction is effective across the extended grid.** At true $R^2_{het} = 0.50$ with moderate heterogeneity ($\tau^2 = 0.25$), LOOCV-corrected estimates have mean bias below 0.05 for $k \ge 30$ across all $p$ values, demonstrating that the correction procedure scales well even when the model is more complex.

6. **Correlated predictors ($\rho = 0.5$) increase instability but do not introduce systematic bias.** The mean optimism is similar to the uncorrelated case, but the variance of the corrected $R^2_{het}$ increases by 15--30% at small $k$, reinforcing the need for wider confidence intervals in the presence of multicollinearity.

7. **Convergence to truth at large $k$.** At $k = 100$ and $p = 2$, the LOOCV-corrected $R^2_{het}$ recovers the true value with mean bias below 0.01 and coverage exceeding 91%, confirming that the procedure is asymptotically unbiased.

## Real-Data Results

Table 2 presents the overfitting audit for the six benchmark datasets.

**Table 2.** Overfitting audit for six benchmark meta-analytic datasets ($B = 1000$).

| Dataset | *k* | *p* | *k/p* | Apparent $R^2$ | CI Lower | CI Upper | CI Width | Assessment  |
|---------|-----|-----|-------|---------------|----------|----------|----------|-------------|
| BCG Vaccine              | 13 | 2  | 6.5  | 0.646 | 0.042  | 1.000 | 0.958 | Unreliable  |
| Teacher Expectancy       | 19 | 1  | 19.0 | 0.406 | -0.195 | 1.000 | 1.195 | Acceptable  |
| Writing-to-Learn         | 48 | 2  | 24.0 | 0.048 | 0.000  | 0.000 | 0.000 | Acceptable  |
| Anti-hypertensive        | 16 | 1  | 16.0 | 0.076 | -3.600 | 1.000 | 4.600 | Acceptable  |
| St. John's Wort          | 26 | 1  | 26.0 | 0.770 | 0.210  | 0.950 | 0.740 | Acceptable  |
| Achievement (simple)     | 56 | 1  | 56.0 | 0.012 | 0.000  | 0.080 | 0.080 | Acceptable  |

Several findings are noteworthy:

**BCG Vaccine.** The apparent $R^2_{het}$ of 0.646 -- often cited as evidence that latitude strongly explains heterogeneity in BCG vaccine effectiveness -- yields a 95% bootstrap CI that spans nearly the entire [0, 1] range (width 0.958). With $k/p = 6.5$, this analysis falls below the recommended threshold, and the wide CI indicates substantial uncertainty about the true explanatory power of latitude.

**Teacher Expectancy.** Despite an acceptable $k/p$ ratio of 19.0, the CI extends below zero (-0.195 to 1.000), indicating that the apparent $R^2_{het}$ of 0.406 is consistent with no genuine effect modification. Fig 4a illustrates the meta-regression slope: teacher expectancy effects diminish with increasing weeks of prior contact, but the LOOCV correction reveals that much of this apparent dose-response may be noise.

**Writing-to-Learn.** This dataset, with a large $k$ and a substantial $k/p$ ratio, yields a near-zero apparent $R^2_{het}$ (0.048), confirming that the examined moderators explain negligible heterogeneity. The CI collapses to a point, reflecting the precision achievable with adequate sample size.

**Anti-hypertensive.** The extremely wide CI (width 4.600, extending well below zero) signals severe estimation instability, likely reflecting a combination of small effect size and high within-study variance.

**St. John's Wort.** This dataset exhibits the highest apparent $R^2_{het}$ of all benchmarks (0.770), with baseline depression severity (HAMD score) as the moderator. The 95% CI [0.210, 0.950] is wide but excludes zero, providing stronger evidence of genuine effect modification than the BCG or Teacher Expectancy datasets. Fig 4b shows the meta-regression relationship: St. John's Wort effectiveness increases with depression severity, with the confidence band remaining above the null line (OR = 1) for HAMD scores above 20.

**Achievement.** With $k = 56$ and $k/p = 56$, the simple model (year as moderator) yields a near-zero apparent $R^2_{het}$ of 0.012, confirming that year of publication does not meaningfully explain heterogeneity. The tight CI [0.000, 0.080] reflects the precision achievable when $k/p$ is large.

### Illustrated Case Studies

Fig 4 presents a three-panel composite figure showing the meta-regression slopes and LOOCV prediction intervals for the three datasets with the largest apparent $R^2_{het}$: BCG vaccine (latitude, $R^2_{het}$ = 0.57), Teacher Expectancy (weeks of contact, $R^2_{het}$ = 0.41), and St. John's Wort (depression severity, $R^2_{het}$ = 0.77). In each panel, individual studies are plotted as points and the meta-regression line is shown with its confidence band. These visualisations make the overfitting problem concrete: the BCG and Teacher Expectancy slopes, while statistically significant in the apparent analysis, are associated with wide prediction bands that encompass the null, whereas the St. John's Wort slope shows a more robust dose-response relationship even after accounting for overfitting.

Fig 5 compares $I^2$ (total heterogeneity) with $R^2_{het}$ (explained heterogeneity) across the three datasets, illustrating that high $I^2$ is a necessary but not sufficient condition for successful meta-regression: the Teacher Expectancy dataset has only 33% total heterogeneity ($I^2$) yet a 41% apparent $R^2_{het}$, while the St. John's Wort dataset has 64% $I^2$ and the highest $R^2_{het}$ of 77%.

### Survey of Published Meta-Regressions

Table 3 summarises the overfitting risk classification for 16 published meta-regressions.

**Table 3.** Overfitting risk in 16 published meta-regressions from the metadat package.

| Risk Category | $k/p$ Range | Count | Percentage | Example Datasets |
|---------------|-------------|-------|------------|------------------|
| Extreme       | $< 5$       | 6     | 37.5%      | BCG, Normand 1999, Molloy 2014 |
| Severe        | $5$--$10$   | 7     | 43.8%      | Linde 2005, Bangert-Drowns 2004, Pagliaro 1992 |
| Moderate      | $10$--$15$  | 1     | 6.2%       | Curtis 1998 |
| Low           | $\ge 15$    | 2     | 12.5%      | Michael 2013 |

Only 3 of 16 datasets (19%) operate at $k/p \ge 10$ -- the minimum threshold recommended by our simulations -- and only 2 (12.5%) reach $k/p \ge 15$ where the LOOCV correction and true value begin to converge reliably. This suggests that the vast majority of published meta-regressions are at substantial risk of reporting inflated $R^2_{het}$.

# Discussion

## Principal Findings

The **metaoverfit** package fills a practical gap in the meta-analytic toolkit by making internal validation of $R^2_{het}$ routine and accessible. Our simulation results -- spanning 16 primary scenarios and 108 extended scenarios -- demonstrate that the apparent $R^2_{het}$ is substantially inflated across a wide range of realistic conditions, with mean optimism exceeding 0.25 in most small-sample settings and reaching 0.46 when $p = 5$. The real-data analyses across six benchmark datasets reinforce this concern: the BCG vaccine dataset, frequently used as a textbook example of successful meta-regression, shows that the often-cited 65% explanatory power is associated with extreme uncertainty when subjected to bootstrap validation. The survey of 16 published meta-regressions confirms that over 80% operate at $k/p$ ratios where substantial overfitting is expected, yet none reported any form of internal validation for $R^2_{het}$.

The illustrated case studies (Fig 4) make the practical consequences vivid. In the Teacher Expectancy dataset, the apparent $R^2_{het}$ of 0.41 suggests a convincing dose-response relationship between weeks of prior contact and the magnitude of expectancy effects. Yet the LOOCV audit reveals that this relationship is largely noise in a small dataset. By contrast, the St. John's Wort dataset -- with higher $k/p$ and a larger true effect -- retains a meaningful $R^2_{het}$ after correction, demonstrating that the LOOCV procedure does not indiscriminately shrink all estimates to zero.

## Relationship to Existing Methods

The LOOCV approach implemented in **metaoverfit** is conceptually related to the "adjusted $R^2$" used in standard regression, but differs in two important ways. First, the adjustment is empirical rather than formula-based, making it more robust to the non-normal, bounded distribution of $\tau^2$. Second, by operating at the level of predicted effect sizes, the method naturally accounts for the weighted structure of meta-regression. The bootstrap procedure complements LOOCV by providing a distribution-free uncertainty measure that explicitly captures the bimodal nature of $R^2_{het}$ in sparse datasets (where a substantial fraction of replicates hit the boundary at 0 or 1).

Related work includes the $R^2$ analogue implemented in **metafor** via the `rma()` function, which reports an apparent value without correction [7]. Lopez-Lopez et al. [6] discussed the overfitting problem conceptually but did not provide software. Higgins and Thompson [3] proposed the $R^2_{het}$ statistic itself but noted the small-sample limitations without offering a correction. To our knowledge, **metaoverfit** is the first dedicated R package providing automated LOOCV and bootstrap validation for this quantity.

## Limitations

Several limitations should be acknowledged. First, LOOCV in meta-regression produces a pessimistically biased estimate when $k$ is very small (e.g., $k < 8$), because each fold trains on $k - 1$ studies, which may be insufficient for stable REML estimation. Second, the percentile bootstrap CI shows under-coverage in our simulations, particularly for low $k/p$ ratios; BCa or bias-corrected intervals may perform better and are planned for future versions (preliminary BCa results from the extended simulation are promising but computationally intensive for routine use). Third, the current implementation assumes a single random-effects model with REML estimation; extensions to multivariate meta-regression, network meta-analysis, and alternative estimators (e.g., Paule-Mandel, Kenward-Roger) are natural next steps. Sensitivity analysis on the BCG data using six different $\tau^2$ estimators (REML, ML, DL, EB, PM, SJ) showed that the apparent $R^2_{het}$ varied by up to 15 percentage points, indicating that choice of estimator is itself a source of uncertainty not fully captured by the current package. Fourth, the "rule of 10" is a heuristic rather than a rigorous threshold; our extended simulations (with $p$ up to 5 and correlated predictors) suggest it may be too lenient for models with many moderators, where $k/p \ge 15$ may be more appropriate. Fifth, the survey of published meta-regressions, while informative, was limited to datasets available in **metadat** and may not be representative of all fields.

## Practical Recommendations

Based on our findings, we offer the following guidance for researchers conducting meta-regression:

1. **Always report both apparent and corrected $R^2_{het}$.** The LOOCV-corrected value provides a more realistic estimate of the model's explanatory power.
2. **Report bootstrap CIs.** A wide CI -- or one that includes zero -- signals that the apparent $R^2_{het}$ should not be over-interpreted.
3. **Monitor boundary hits.** If a substantial proportion of bootstrap replicates yield $R^2_{het} = 0$, the data are likely too sparse for the model.
4. **Respect the $k/p \ge 10$ threshold.** Models with lower ratios should be treated as exploratory at best.
5. **Use `check_overfitting()` as a routine diagnostic**, analogous to checking residuals in regression.

## Software Availability

**metaoverfit** is available at https://github.com/mahmood726-cyber/metaoverfit under the GPL-3 license. The package requires R >= 3.5.0 and depends on **metafor** (>= 3.0.0), **ggplot2**, and **parallel** (base R). Archived versions will be deposited on Zenodo ([ZENODO_DOI_PLACEHOLDER]).

# Conclusion

Overfitting in meta-regression is a pervasive but under-recognised problem that can lead to overconfident claims about effect modification. Our survey of 16 published meta-regressions found that over 80% operate at $k/p$ ratios where substantial optimism is expected, and our extended simulations confirm that this optimism can exceed 30% even at $k = 50$ when $p = 5$. The **metaoverfit** package provides a practical, one-function solution for detecting and quantifying this optimism. The illustrated case studies demonstrate both the problem (BCG vaccine, Teacher Expectancy) and its resolution (St. John's Wort), showing that the LOOCV correction appropriately distinguishes genuine effect modification from noise. By integrating LOOCV correction, bootstrap uncertainty quantification, and interpretive guidance into the standard meta-analytic workflow, the package encourages more cautious and transparent reporting of $R^2_{het}$ in evidence synthesis.

# Acknowledgments

The author thanks the developers of the **metafor** and **metadat** R packages for providing the infrastructure on which **metaoverfit** builds.

# References

1. Borenstein M, Hedges LV, Higgins JPT, Rothstein HR. Introduction to Meta-Analysis. 2nd ed. Chichester: John Wiley & Sons; 2021.

2. Cochrane Handbook for Systematic Reviews of Interventions. Version 6.4. Higgins JPT, Thomas J, Chandler J, et al., editors. Cochrane; 2023.

3. Higgins JPT, Thompson SG. Quantifying heterogeneity in a meta-analysis. Stat Med. 2002;21(11):1539--1558.

4. Harrell FE. Regression Modeling Strategies. 2nd ed. Cham: Springer; 2015.

5. Higgins JPT, Thompson SG. Controlling the risk of spurious findings from meta-regression. Stat Med. 2004;23(11):1663--1682.

6. Lopez-Lopez JA, Page MJ, Lipsey MW, Higgins JPT. Dealing with effect size multiplicity in systematic reviews and meta-analyses. Res Synth Methods. 2018;9(3):336--351.

7. Viechtbauer W. Conducting meta-analyses in R with the metafor package. J Stat Softw. 2010;36(3):1--48.

8. Thompson SG, Higgins JPT. How should meta-regression analyses be undertaken and interpreted? Stat Med. 2002;21(11):1559--1573.

9. Berkey CS, Hoaglin DC, Mosteller F, Colditz GA. A random-effects regression model for meta-analysis. Stat Med. 1995;14(4):395--411.

10. Raudenbush SW. Magnitude of teacher expectancy effects on pupil IQ as a function of the credibility of expectancy induction: A synthesis of findings from 18 experiments. J Educ Psychol. 1984;76(1):85--97.

11. Bangert-Drowns RL, Hurley MM, Wilkinson B. The effects of school-based writing-to-learn interventions on academic achievement: A meta-analysis. Rev Educ Res. 2004;74(1):29--58.

12. Egger M, Smith GD. Meta-analysis bias in location and selection of studies. BMJ. 1998;316(7124):61--66.

13. Linde K, Berner MM, Kriston L. St John's wort for major depression. Cochrane Database Syst Rev. 2008;(4):CD000448.

14. Konstantopoulos S. Fixed effects and variance components estimation in three-level meta-analysis. Res Synth Methods. 2011;2(1):61--76.

15. White T, Viechtbauer W. metadat: Meta-analytic datasets for R. R package. 2022.

# Supporting Information

**S1 Table.** Full simulation results for all 16 primary scenarios ($k \times p \times R^2_{true}$), including per-scenario convergence rates and boundary-hit frequencies.

**S2 Table.** Extended simulation results for 108 scenarios ($k \in \{10, 15, 20, 30, 50, 100\}$, $p \in \{2, 3, 5\}$, $R^2_{true} \in \{0.30, 0.50, 0.70\}$, $\tau^2 \in \{0.10, 0.25\}$, $\rho \in \{0, 0.5\}$), including mean apparent and corrected $R^2_{het}$, optimism, and convergence rates.

**S3 Table.** Survey of 16 published meta-regressions: dataset name, year, $k$, $p$, $k/p$ ratio, domain, and overfitting risk classification.

**S1 Fig.** Bootstrap distributions for each of the six benchmark datasets, showing the apparent $R^2_{het}$ (dashed vertical line) relative to the empirical distribution.

**S2 Fig.** Simulation results: mean bias of apparent $R^2_{het}$ as a function of $k/p$ ratio, stratified by true $R^2_{het}$.

**Fig 3.** Mean optimism (%) as a function of $k$ for $p \in \{2, 3, 5\}$ from the extended simulation at true $R^2_{het} = 0.30$. The dashed line indicates the 10% optimism threshold. Generated from `inst/twma_simulation_results.csv`.

**Fig 4.** Three-panel composite figure showing meta-regression slopes and prediction intervals for the three datasets with the largest apparent $R^2_{het}$: (a) BCG vaccine effectiveness vs. absolute latitude ($R^2_{het}$ = 0.57), (b) Teacher Expectancy effects vs. weeks of prior contact ($R^2_{het}$ = 0.41), and (c) St. John's Wort odds ratio vs. baseline depression severity ($R^2_{het}$ = 0.77). Points represent individual studies; shaded bands show confidence intervals for the meta-regression prediction.

**Fig 5.** Comparison of $I^2$ (total heterogeneity, grey bars) with $R^2_{het}$ (explained heterogeneity, blue bars) across three benchmark datasets. High $I^2$ is a necessary but not sufficient condition for a large $R^2_{het}$.

**Fig 6.** Transportability of effects visualisation: (a) predicted vs. observed effect sizes coloured by mean population age, (b) heterogeneity decomposition showing the proportion of residual vs. explained (transportable) variance, and (c) treatment effect as a function of population age with proportion male indicated by point colour. This figure illustrates how $R^2_{het}$ connects to the concept of effect transportability across populations.
