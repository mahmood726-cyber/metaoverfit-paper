## ============================================================================
## COMPLETE WORKING EXAMPLE: R2het Analysis with BCG Data
## Uses the metaoverfit package API. Ready to run after install.
## ============================================================================

rm(list = ls())

library(metafor)
library(ggplot2)
library(metaoverfit)

# ============================================================================
# STEP 1: LOAD AND PREPARE BCG DATA
# ============================================================================

cat("\n============================================================\n")
cat("R2het ANALYSIS: BCG VACCINE TRIALS\n")
cat("============================================================\n\n")

data(dat.bcg)
dat <- escalc(measure = "RR",
              ai = tpos, bi = tneg,
              ci = cpos, di = cneg,
              data = dat.bcg)

cat("Dataset Overview:\n")
cat("- Studies:", nrow(dat), "\n")
cat("- Effect size: log risk ratio\n")
cat("- Moderator: absolute latitude\n\n")

# ============================================================================
# STEP 2: FULL OVERFITTING AUDIT
# ============================================================================

cat("Running full overfitting audit (B = 1000)...\n")
cat("This may take 1-2 minutes.\n\n")

set.seed(42)
res <- check_overfitting(
  yi   = yi,
  vi   = vi,
  mods = ~ ablat,
  data = dat,
  B    = 1000,
  parallel = FALSE
)
print(res)

# ============================================================================
# STEP 3: VISUALISATION
# ============================================================================

cat("\nCreating plots...\n")

p1 <- plot_overfitting(res, type = "bar")
ggsave("bcg_r2het_analysis.png", p1, width = 8, height = 5, dpi = 300)
cat("Bar plot saved as 'bcg_r2het_analysis.png'\n")

p2 <- plot_overfitting(res, type = "histogram")
ggsave("bcg_r2het_bootstrap.png", p2, width = 8, height = 5, dpi = 300)
cat("Histogram saved as 'bcg_r2het_bootstrap.png'\n")

# ============================================================================
# STEP 4: SENSITIVITY ANALYSIS ACROSS TAU2 ESTIMATORS
# ============================================================================

cat("\n============================================================\n")
cat("SENSITIVITY ANALYSIS: COMPARING TAU-SQUARED ESTIMATORS\n")
cat("============================================================\n\n")

methods_to_test <- c("REML", "DL", "ML", "PM")
estimator_results <- data.frame()

for (method in methods_to_test) {
  cat("Testing", method, "... ")
  tryCatch({
    fit_n <- rma(yi, vi, data = dat, method = method)
    fit_f <- rma(yi, vi, mods = ~ ablat, data = dat, method = method)
    r2 <- calculate_r2het(fit_n$tau2, fit_f$tau2)
    estimator_results <- rbind(estimator_results, data.frame(
      Method    = method,
      tau2_null = round(fit_n$tau2, 4),
      tau2_full = round(fit_f$tau2, 4),
      R2het     = round(r2, 3)
    ))
    cat("Done\n")
  }, error = function(e) cat("Failed:", conditionMessage(e), "\n"))
}

print(estimator_results)

# ============================================================================
# STEP 5: SAVE RESULTS
# ============================================================================

cat("\nSaving results...\n")

saveRDS(res, "bcg_bootstrap_results.rds")
cat("Bootstrap results: bcg_bootstrap_results.rds\n")

summary_df <- data.frame(
  Metric = c("R2het (apparent)", "R2het (corrected)", "Optimism",
             "95% CI Lower", "95% CI Upper", "CI Width",
             "Studies (k)", "Moderators (p)", "k/p ratio",
             "Boundary hits (%)"),
  Value = c(sprintf("%.3f", res$apparent),
            sprintf("%.3f", res$corrected),
            sprintf("%.3f", res$optimism),
            sprintf("%.3f", res$ci[1]),
            sprintf("%.3f", res$ci[2]),
            sprintf("%.3f", res$ci[2] - res$ci[1]),
            as.character(res$k),
            as.character(res$p),
            sprintf("%.1f", res$kp_ratio),
            sprintf("%.1f", res$boundary_rate * 100))
)
write.csv(summary_df, "bcg_results_summary.csv", row.names = FALSE)
cat("Summary CSV: bcg_results_summary.csv\n")

# Save complete workspace
save.image("complete_analysis.RData")
cat("Workspace: complete_analysis.RData\n\n")

cat("============================================================\n")
cat("ANALYSIS COMPLETE\n")
cat("============================================================\n")
