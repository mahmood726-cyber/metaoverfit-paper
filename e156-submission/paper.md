Mahmood Ahmad
Tahir Heart Institute
author@example.com

Overfitting in Published Meta-Regressions: Simulation and Empirical Survey

How frequently do published meta-regressions operate in statistical regimes where apparent explanatory power is substantially inflated by overfitting? We combined simulation experiments across 18 parameter configurations with an empirical survey of 16 published meta-regressions from the metadat package spanning medicine, education, and domains. The metaoverfit R package computed LOOCV-corrected R-squared alongside bootstrap confidence intervals for each benchmark, testing whether reported explanatory power survives internal validation. Mean calibration optimism was 0.31 (95% CI 0.13 to 0.49) for two predictors and exceeded 0.30 for five predictors, with severe distortion when the studies-to-predictors ratio fell below ten. Among the 16 published analyses surveyed, 6 had extreme risk and 7 had severe overfitting risk, meaning 81 percent operated in unreliable regimes. Case studies on teacher expectancy, BCG vaccine, and herbal antidepressant datasets showed that overfitting audits substantively changed interpretation of regression slopes. A limitation is that the survey of 16 meta-regressions may not fully represent the broader published methodological literature.

Outside Notes

Type: methods
Primary estimand: R-squared optimism
App: metaoverfit R package v0.2.0
Data: 18 simulation configs, 16 published meta-regressions
Code: https://github.com/mahmood726-cyber/metaoverfit-paper
Version: 0.2.0
Validation: DRAFT

References

1. Thompson SG, Higgins JPT. How should meta-regression analyses be undertaken and interpreted? Stat Med. 2002;21(11):1559-1573.
2. Viechtbauer W. Conducting meta-analyses in R with the metafor package. J Stat Softw. 2010;36(3):1-48.
3. Borenstein M, Hedges LV, Higgins JPT, Rothstein HR. Introduction to Meta-Analysis. 2nd ed. Wiley; 2021.
