## ============================================================================
## QUICK START GUIDE: metaoverfit in RStudio
## ============================================================================

# STEP 1: Install Required Packages ----------------------------------------
install.packages(c("metafor", "ggplot2", "metadat", "remotes"))

# STEP 2: Install metaoverfit from GitHub -----------------------------------
remotes::install_github("mahmood726-cyber/metaoverfit")

# STEP 3: Quick Test with Example Data -------------------------------------
library(metafor)
library(metaoverfit)
library(metadat)

data(dat.bcg)
dat <- escalc(measure = "RR", ai = tpos, bi = tneg,
              ci = cpos, di = cneg, data = dat.bcg)

# One-line overfitting audit
set.seed(42)
res <- check_overfitting(
  yi   = yi,
  vi   = vi,
  mods = ~ ablat,
  data = dat,
  B    = 500
)
print(res)

# Visualise
plot_overfitting(res, type = "bar")
plot_overfitting(res, type = "histogram")

# Sample size guidance
sample_size_recommendation(p = 2)

# STEP 4: Run Your Own Analysis ---------------------------------------------
# my_data <- read.csv("your_data.csv")
# my_data <- escalc(measure = "MD",
#                    m1i = mean_tx, sd1i = sd_tx, n1i = n_tx,
#                    m2i = mean_ctrl, sd2i = sd_ctrl, n2i = n_ctrl,
#                    data = my_data)
# res <- check_overfitting(yi, vi, mods = ~ mod1 + mod2, data = my_data,
#                          B = 1000, parallel = TRUE)
# print(res)

# ============================================================================
# TROUBLESHOOTING
# ============================================================================
# Issue: "Error in rma(): 'yi' has non-finite values"
#   => Check for NA or Inf: sum(is.na(dat$yi)); sum(is.infinite(dat$yi))
#
# Issue: Bootstrap taking too long
#   => Use parallel = TRUE and/or reduce B
#
# Issue: Wide confidence intervals
#   => Check k/p ratio; may need more studies
