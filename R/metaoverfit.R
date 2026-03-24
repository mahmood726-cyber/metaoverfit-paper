#' Calculate R-squared heterogeneity (R2het)
#'
#' @description Computes the proportion of between-study heterogeneity explained
#'   by moderators, defined as \eqn{1 - \tau^2_{full} / \tau^2_{null}}, bounded
#'   to \eqn{[0, 1]}.
#'
#' @param tau2_null The tau-squared estimate from the null model (no moderators).
#' @param tau2_full The tau-squared estimate from the full model (with moderators).
#' @return The calculated R2het value bounded between 0 and 1.
#' @examples
#' calculate_r2het(0.5, 0.25)  # 0.5
#' calculate_r2het(0.5, 0.6)   # 0 (bounded)
#' @export
calculate_r2het <- function(tau2_null, tau2_full) {
  if (is.null(tau2_null) || is.null(tau2_full)) return(0)
  if (is.na(tau2_null) || is.na(tau2_full) || tau2_null <= 0) return(0)
  r2 <- (tau2_null - tau2_full) / tau2_null
  max(0, min(1, r2))
}

#' Cross-validated R2het for meta-regression
#'
#' @description Computes an optimism-corrected R-squared heterogeneity measure
#'   using leave-one-out cross-validation (LOOCV). Each study is held out in
#'   turn, the model is refit on the remaining \eqn{k-1} studies, and a
#'   predicted effect size is obtained for the held-out study. The
#'   cross-validated MSE is then used to derive a corrected \eqn{\tau^2}.
#'
#' @param yi Vector of effect sizes.
#' @param vi Vector of sampling variances.
#' @param mods Model matrix of moderators (should include intercept column).
#' @param cv_method Cross-validation method. Currently only \code{"loo"}
#'   (leave-one-out) is supported.
#' @param verbose Logical. Print progress to the console.
#' @return A list with components:
#'   \describe{
#'     \item{r2het_apparent}{Apparent R2het from the full sample.}
#'     \item{r2het_corrected}{Cross-validated (optimism-corrected) R2het.}
#'     \item{optimism}{Estimated optimism (apparent minus corrected, floored at 0).}
#'   }
#' @importFrom metafor rma
#' @importFrom stats predict
#' @export
r2het_cv <- function(yi, vi, mods, cv_method = "loo", verbose = FALSE) {
  if (cv_method != "loo") stop("Only 'loo' is supported.")

  yi <- as.numeric(yi)
  vi <- as.numeric(vi)
  k <- length(yi)

  if (k < 4) stop("Need at least k = 4 studies for LOOCV.")
  if (length(vi) != k) stop("yi and vi must have the same length.")

  mods <- as.matrix(mods)
  if (nrow(mods) != k) stop("mods must have the same number of rows as yi.")

  fit_null <- suppressWarnings(metafor::rma(yi = yi, vi = vi, method = "REML"))
  fit_full <- suppressWarnings(metafor::rma(yi = yi, vi = vi, mods = mods,
                                            method = "REML"))
  r2_app <- calculate_r2het(fit_null$tau2, fit_full$tau2)

  preds <- numeric(k)
  for (i in 1:k) {
    if (verbose) cat(sprintf("\rCV fold %d/%d", i, k))
    fit_i <- tryCatch(
      suppressWarnings(metafor::rma(yi = yi[-i], vi = vi[-i],
                                    mods = mods[-i, , drop = FALSE],
                                    method = "REML")),
      error = function(e) return(NULL)
    )
    if (is.null(fit_i)) {
      preds[i] <- NA
    } else {
      # metafor::predict.rma expects newmods WITHOUT intercept when the model
      # includes an intercept (default). If the model matrix has an intercept
      # column (all 1s), strip it for prediction.
      nm <- mods[i, , drop = FALSE]
      if (ncol(nm) > 1 && !isTRUE(fit_i$int.only)) {
        nm <- nm[, -1, drop = FALSE]
      }
      preds[i] <- suppressWarnings(predict(fit_i, newmods = nm))$pred
    }
  }
  if (verbose) cat("\n")

  valid_idx <- !is.na(preds)
  if (sum(valid_idx) < 3) {
    warning("Fewer than 3 valid CV predictions; results may be unreliable.")
  }
  mse_cv <- mean((yi[valid_idx] - preds[valid_idx])^2)
  tau2_cv <- max(0, mse_cv - mean(vi[valid_idx]))
  r2_cv <- calculate_r2het(fit_null$tau2, tau2_cv)

  list(r2het_apparent = r2_app,
       r2het_corrected = r2_cv,
       optimism = max(0, r2_app - r2_cv))
}

#' Bootstrap confidence intervals and optimism correction
#'
#' @description Computes non-parametric bootstrap confidence intervals for
#'   \eqn{R^2_{het}} and diagnoses boundary effects (bootstrap replicates
#'   where \eqn{\tau^2 = 0}).
#'
#' @param yi Vector of effect sizes.
#' @param vi Vector of sampling variances.
#' @param mods Model matrix of moderators (should include intercept column).
#' @param B Number of bootstrap replicates (default 500).
#' @param conf_level Confidence level for percentile intervals (default 0.95).
#' @param parallel Logical. Use parallel processing via the \pkg{parallel}
#'   package? Default \code{FALSE}.
#' @return A list with components:
#'   \describe{
#'     \item{ci}{Percentile confidence interval (named numeric of length 2).}
#'     \item{boot_mean}{Mean of valid bootstrap replicates.}
#'     \item{boot_median}{Median of valid bootstrap replicates.}
#'     \item{n_valid}{Number of valid (non-NA) replicates.}
#'     \item{n_boundary}{Number of replicates where R2het = 0 (boundary hit).}
#'     \item{boundary_rate}{Proportion of boundary hits.}
#'     \item{r2_boot_all}{Vector of all valid bootstrap R2het values.}
#'   }
#' @importFrom metafor rma
#' @importFrom stats quantile median
#' @importFrom parallel makeCluster stopCluster parLapply clusterExport detectCores
#' @export
r2het_boot <- function(yi, vi, mods, B = 500, conf_level = 0.95,
                       parallel = FALSE) {
  yi <- as.numeric(yi)
  vi <- as.numeric(vi)
  k <- length(yi)
  mods <- as.matrix(mods)

  boot_func <- function(b) {
    idx <- sample(1:k, replace = TRUE)
    yi_b <- yi[idx]
    vi_b <- vi[idx]
    mods_b <- mods[idx, , drop = FALSE]
    fn_b <- tryCatch(
      suppressWarnings(metafor::rma(yi = yi_b, vi = vi_b, method = "REML")),
      error = function(e) NULL)
    ff_b <- tryCatch(
      suppressWarnings(metafor::rma(yi = yi_b, vi = vi_b, mods = mods_b,
                                    method = "REML")),
      error = function(e) NULL)
    if (is.null(fn_b) || is.null(ff_b)) return(NA)
    calculate_r2het(fn_b$tau2, ff_b$tau2)
  }

  if (parallel) {
    ncores <- max(1, parallel::detectCores() - 1)
    cl <- parallel::makeCluster(ncores)
    on.exit(parallel::stopCluster(cl), add = TRUE)
    parallel::clusterExport(cl,
      varlist = c("yi", "vi", "mods", "k", "calculate_r2het"),
      envir = environment())
    boot_reps <- unlist(parallel::parLapply(cl, 1:B, boot_func))
  } else {
    boot_reps <- vapply(1:B, boot_func, numeric(1))
  }

  valid_reps <- boot_reps[!is.na(boot_reps)]
  n_boundary <- sum(valid_reps == 0)
  alpha <- 1 - conf_level
  ci <- quantile(valid_reps, probs = c(alpha / 2, 1 - alpha / 2), na.rm = TRUE)

  list(ci = ci,
       boot_mean = mean(valid_reps),
       boot_median = median(valid_reps),
       n_valid = length(valid_reps),
       n_boundary = n_boundary,
       boundary_rate = n_boundary / max(1, length(valid_reps)),
       r2_boot_all = valid_reps)
}

#' Full overfitting check for meta-regression
#'
#' @description A convenience wrapper that runs both LOOCV and bootstrap
#'   analyses, returning a single \code{metaoverfit_check} object with a
#'   formatted \code{print} method.
#'
#' @param yi Vector of effect sizes, or an unquoted variable name in \code{data}.
#' @param vi Vector of sampling variances, or an unquoted variable name in
#'   \code{data}.
#' @param mods A one-sided formula (e.g. \code{~ x1 + x2}) or a model matrix.
#' @param data Data frame containing the variables referenced in \code{yi},
#'   \code{vi}, and \code{mods}.
#' @param B Number of bootstrap replicates (default 500).
#' @param conf_level Confidence level (default 0.95).
#' @param parallel Logical. Use parallel processing? Default \code{FALSE}.
#' @return An object of class \code{"metaoverfit_check"} with components:
#'   \describe{
#'     \item{apparent}{Apparent R2het.}
#'     \item{corrected}{LOOCV-corrected R2het.}
#'     \item{optimism}{Estimated optimism.}
#'     \item{ci}{Bootstrap percentile confidence interval.}
#'     \item{B}{Number of bootstrap replicates used.}
#'     \item{k}{Number of studies.}
#'     \item{p}{Number of moderator predictors (excluding intercept).}
#'     \item{kp_ratio}{Ratio k/p.}
#'     \item{n_boundary}{Number of boundary (R2het = 0) bootstrap replicates.}
#'     \item{boundary_rate}{Proportion of boundary hits.}
#'     \item{boot_reps}{Vector of bootstrap R2het replicates.}
#'   }
#' @importFrom stats model.matrix
#' @examples
#' \dontrun{
#' library(metafor); library(metadat)
#' data(dat.bcg)
#' dat <- escalc(measure = "RR", ai = tpos, bi = tneg,
#'               ci = cpos, di = cneg, data = dat.bcg)
#' res <- check_overfitting(yi, vi, mods = ~ablat, data = dat, B = 200)
#' print(res)
#' }
#' @export
check_overfitting <- function(yi, vi, mods, data, B = 500, conf_level = 0.95,
                              parallel = FALSE) {
  y_val <- eval(substitute(yi), data, parent.frame())
  v_val <- eval(substitute(vi), data, parent.frame())

  mod_matrix <- if (inherits(mods, "formula")) {
    stats::model.matrix(mods, data)
  } else {
    as.matrix(mods)
  }

  cv_res <- r2het_cv(y_val, v_val, mod_matrix)
  boot_res <- r2het_boot(y_val, v_val, mod_matrix, B = B,
                         conf_level = conf_level, parallel = parallel)

  p_count <- ncol(mod_matrix) - 1L  # exclude intercept
  res <- list(
    apparent      = cv_res$r2het_apparent,
    corrected     = cv_res$r2het_corrected,
    optimism      = cv_res$optimism,
    ci            = boot_res$ci,
    conf_level    = conf_level,
    B             = B,
    k             = length(y_val),
    p             = p_count,
    kp_ratio      = length(y_val) / max(1, p_count),
    n_boundary    = boot_res$n_boundary,
    boundary_rate = boot_res$boundary_rate,
    boot_reps     = boot_res$r2_boot_all
  )
  class(res) <- "metaoverfit_check"
  res
}

#' @export
print.metaoverfit_check <- function(x, ...) {
  # Derive confidence level from quantile names (e.g. "2.5%" and "97.5%")
  ci_names <- names(x$ci)
  if (!is.null(ci_names) && length(ci_names) == 2) {
    probs <- as.numeric(sub("%", "", ci_names)) / 100
    conf_pct <- round((probs[2] - probs[1]) * 100)
  } else {
    conf_pct <- 95
  }

  cat("Meta-Regression Overfitting Audit\n")
  cat("==================================\n")
  cat(sprintf("Studies (k): %d | Moderators (p): %d | k/p ratio: %.1f\n",
              x$k, x$p, x$kp_ratio))
  cat(sprintf("Apparent R2_het:    %.3f\n", x$apparent))
  cat(sprintf("LOOCV R2_het:       %.3f\n", x$corrected))
  cat(sprintf("Estimated optimism: %.3f\n", x$optimism))
  cat(sprintf("%d%% Bootstrap CI:   [%.3f, %.3f]  (B = %d)\n",
              conf_pct, x$ci[1], x$ci[2], x$B))
  cat(sprintf("Boundary hits:      %d / %d (%.1f%%)\n",
              x$n_boundary, length(x$boot_reps),
              x$boundary_rate * 100))

  if (x$kp_ratio < 10) {
    cat("\n** WARNING: k/p ratio < 10. Model stability is questionable.\n")
    cat("   Consider reducing the number of moderators or collecting more studies.\n")
  }
  invisible(x)
}

#' Plot overfitting analysis
#'
#' @description Creates a bar chart comparing apparent vs. LOOCV-corrected
#'   R2het, or a histogram of bootstrap replicates.
#'
#' @param x Result from \code{\link{check_overfitting}} or \code{\link{r2het_cv}}.
#' @param type \code{"bar"} for a bar chart (default) or \code{"histogram"} for
#'   the bootstrap distribution (requires a \code{metaoverfit_check} object).
#' @return A \code{ggplot} object.
#' @import ggplot2
#' @export
plot_overfitting <- function(x, type = "bar") {
  if (inherits(x, "metaoverfit_check")) {
    app  <- x$apparent
    corr <- x$corrected
    opt  <- x$optimism
  } else {
    app  <- x$r2het_apparent
    corr <- x$r2het_corrected
    opt  <- x$optimism
  }

  Measure <- R2het <- NULL  # avoid R CMD check NOTE

  if (type == "histogram" && inherits(x, "metaoverfit_check")) {
    df_hist <- data.frame(R2het = x$boot_reps)
    p <- ggplot(df_hist, aes(x = R2het)) +
      geom_histogram(bins = 40, fill = "steelblue", colour = "white",
                     alpha = 0.8) +
      geom_vline(xintercept = app, colour = "#D95F02", linewidth = 1,
                 linetype = "dashed") +
      geom_vline(xintercept = corr, colour = "#1B9E77", linewidth = 1,
                 linetype = "dashed") +
      theme_minimal() +
      labs(title = "Bootstrap Distribution of R2het",
           subtitle = sprintf("Orange = apparent (%.3f), Green = corrected (%.3f)",
                              app, corr),
           x = expression(R[het]^2), y = "Count") +
      xlim(0, 1)
    return(p)
  }

  df <- data.frame(
    Measure = factor(c("Apparent", "Corrected"),
                     levels = c("Apparent", "Corrected")),
    R2het = c(app, corr)
  )

  ggplot(df, aes(x = Measure, y = R2het, fill = Measure)) +
    geom_bar(stat = "identity", width = 0.5) +
    scale_fill_manual(values = c("Apparent" = "#D95F02",
                                 "Corrected" = "#1B9E77")) +
    theme_minimal() +
    labs(title = "R-squared Heterogeneity: Apparent vs. Corrected",
         subtitle = sprintf("Estimated Optimism: %.3f", opt),
         y = expression(R[het]^2), x = "") +
    ylim(0, 1)
}

#' Sample size recommendation for meta-regression
#'
#' @description Provides guidance on the minimum number of studies \eqn{k}
#'   required for a given number of moderators \eqn{p}, based on the "rule of
#'   10" heuristic (\eqn{k/p \ge 10}).
#'
#' @param p Number of moderator parameters (excluding intercept).
#' @param target_optimism Target maximum optimism (default 0.10). Currently used
#'   for informational messaging only; the heuristic is \eqn{k \ge 10p}.
#' @return The recommended minimum \eqn{k} (invisibly).
#' @examples
#' sample_size_recommendation(p = 2)
#' sample_size_recommendation(p = 5)
#' @export
sample_size_recommendation <- function(p, target_optimism = 0.10) {
  if (!is.numeric(p) || length(p) != 1 || p < 1) {
    stop("p must be a positive integer.")
  }
  k_req <- ceiling(p * 10)
  cat(sprintf(
    "Guidance: With %d moderator(s), aim for k >= %d studies (k/p >= 10).\n",
    p, k_req))
  cat(sprintf(
    "  Target max optimism: %.0f%%. Below this threshold, cross-validated\n",
    target_optimism * 100))
  cat("  and apparent R2het should be reasonably close.\n")
  invisible(k_req)
}

# Suppress R CMD check NOTEs for ggplot aesthetics
utils::globalVariables(c("Measure", "R2het"))
