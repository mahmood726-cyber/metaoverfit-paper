library(testthat)
library(metaoverfit)
library(metafor)

# ============================================================================
# calculate_r2het
# ============================================================================

test_that("calculate_r2het works correctly and handles bounds", {
 expect_equal(calculate_r2het(0.5, 0.25), 0.5)
 expect_equal(calculate_r2het(0.5, 0.5), 0)
 expect_equal(calculate_r2het(0.5, 0.6), 0)   # bounded at 0
 expect_equal(calculate_r2het(0.5, 0.0), 1)   # bounded at 1
 expect_equal(calculate_r2het(0, 0.1), 0)     # tau2_null = 0 edge case
 expect_equal(calculate_r2het(NA, 0.1), 0)    # NA input
 expect_equal(calculate_r2het(NULL, 0.1), 0)  # NULL input
})

# ============================================================================
# sample_size_recommendation
# ============================================================================

test_that("sample_size_recommendation returns correct value", {
 expect_equal(sample_size_recommendation(p = 2), 20)
 expect_equal(sample_size_recommendation(p = 5), 50)
 expect_error(sample_size_recommendation(p = 0))
 expect_error(sample_size_recommendation(p = -1))
})

# ============================================================================
# r2het_cv
# ============================================================================

test_that("r2het_cv works with simulated numeric data", {
 set.seed(123)
 k <- 20
 yi <- rnorm(k)
 vi <- runif(k, 0.01, 0.1)
 x <- rnorm(k)
 yi <- yi + x  # moderator explains variance
 mods <- cbind(1, x)

 res <- r2het_cv(yi = yi, vi = vi, mods = mods)

 expect_type(res, "list")
 expect_named(res, c("r2het_apparent", "r2het_corrected", "optimism"))
 expect_true(res$r2het_apparent >= 0 && res$r2het_apparent <= 1)
 expect_true(res$r2het_corrected >= 0 && res$r2het_corrected <= 1)
 expect_true(res$optimism >= 0)
 # Apparent should be >= corrected (optimism is non-negative by construction)
 expect_true(res$r2het_apparent >= res$r2het_corrected)
})

test_that("r2het_cv rejects too few studies", {
 expect_error(r2het_cv(1:3, rep(0.1, 3), cbind(1, 1:3)),
              "at least k = 4")
})

# ============================================================================
# r2het_boot
# ============================================================================

test_that("r2het_boot returns expected structure", {
 set.seed(42)
 k <- 15
 yi <- rnorm(k)
 vi <- runif(k, 0.01, 0.1)
 mods <- cbind(1, rnorm(k))

 res <- r2het_boot(yi, vi, mods, B = 20, conf_level = 0.95)

 expect_type(res, "list")
 expect_true("ci" %in% names(res))
 expect_true("boot_mean" %in% names(res))
 expect_true("n_valid" %in% names(res))
 expect_true("n_boundary" %in% names(res))
 expect_true("boundary_rate" %in% names(res))
 expect_true("r2_boot_all" %in% names(res))
 expect_equal(length(res$ci), 2)
 expect_true(res$ci[1] <= res$ci[2])
})

# ============================================================================
# check_overfitting
# ============================================================================

test_that("check_overfitting works with data frames and formula", {
 set.seed(123)
 k <- 20
 dat <- data.frame(
   y = rnorm(k),
   v = runif(k, 0.01, 0.1),
   x = rnorm(k)
 )

 res <- check_overfitting(y, v, mods = ~ x, data = dat, B = 20)

 expect_s3_class(res, "metaoverfit_check")
 expect_equal(res$k, 20)
 expect_equal(res$p, 1)
 expect_equal(res$kp_ratio, 20)
 expect_true(res$apparent >= 0 && res$apparent <= 1)
 expect_true(res$corrected >= 0 && res$corrected <= 1)
 expect_equal(length(res$ci), 2)
})

test_that("print.metaoverfit_check runs without error", {
 set.seed(99)
 k <- 15
 dat <- data.frame(y = rnorm(k), v = runif(k, 0.01, 0.1), x = rnorm(k))
 res <- check_overfitting(y, v, mods = ~ x, data = dat, B = 10)
 expect_output(print(res), "Overfitting Audit")
})

# ============================================================================
# plot_overfitting
# ============================================================================

test_that("plot_overfitting returns a ggplot object", {
 set.seed(1)
 k <- 15
 yi <- rnorm(k)
 vi <- runif(k, 0.01, 0.1)
 mods <- cbind(1, rnorm(k))
 cv_out <- r2het_cv(yi, vi, mods)

 p <- plot_overfitting(cv_out, type = "bar")
 expect_s3_class(p, "gg")
})

test_that("plot_overfitting histogram works with metaoverfit_check", {
 set.seed(2)
 k <- 15
 dat <- data.frame(y = rnorm(k), v = runif(k, 0.01, 0.1), x = rnorm(k))
 res <- check_overfitting(y, v, mods = ~ x, data = dat, B = 20)

 p <- plot_overfitting(res, type = "histogram")
 expect_s3_class(p, "gg")
})
