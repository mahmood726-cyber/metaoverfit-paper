Mahmood Ahmad
Tahir Heart Institute
mahmood.ahmad2@nhs.net

Overfitting in Published Meta-Regressions: Simulation and Empirical Survey

How frequently do published meta-regressions operate in statistical regimes where apparent explanatory power is substantially inflated by overfitting? We combined simulation experiments across 18 parameter configurations with an empirical survey of 16 published meta-regressions from the metadat package spanning medicine, education, and psychiatry domains. The metaoverfit R package computed LOOCV-corrected R-squared alongside bootstrap confidence intervals for each benchmark, testing whether reported explanatory power survives internal validation. Mean optimism was 0.31 (95% CI 0.13 to 0.49) for two predictors and exceeded 0.30 for five predictors, with severe distortion when the studies-to-predictors ratio fell below ten. Among the 16 published analyses surveyed, 6 had extreme risk and 7 had severe overfitting risk, meaning 81 percent operated in unreliable regimes. Case studies on teacher expectancy, BCG vaccine, and herbal antidepressant datasets showed that overfitting audits substantively changed interpretation of regression slopes. A limitation is that the survey of 16 meta-regressions may not fully represent the broader published methodological literature.

Outside Notes

Type: methods
Primary estimand: R-squared optimism
App: metaoverfit R package v0.2.0
Data: 18 simulation configs, 16 published meta-regressions
Code: https://github.com/mahmood726-cyber/metaoverfit-paper
Version: 0.2.0
Validation: DRAFT

References

1. Viechtbauer W. Conducting meta-analyses in R with the metafor package. J Stat Softw. 2010;36(3):1-48.
2. Schwarzer G, Carpenter JR, Rucker G. Meta-Analysis with R. Springer; 2015.
3. Borenstein M, Hedges LV, Higgins JPT, Rothstein HR. Introduction to Meta-Analysis. 2nd ed. Wiley; 2021.

AI Disclosure

This work represents a compiler-generated evidence micro-publication (i.e., a structured, pipeline-based synthesis output). AI is used as a constrained synthesis engine operating on structured inputs and predefined rules, rather than as an autonomous author. Deterministic components of the pipeline, together with versioned, reproducible evidence capsules (TruthCert), are designed to support transparent and auditable outputs. All results and text were reviewed and verified by the author, who takes full responsibility for the content. The workflow operationalises key transparency and reporting principles consistent with CONSORT-AI/SPIRIT-AI, including explicit input specification, predefined schemas, logged human-AI interaction, and reproducible outputs.
