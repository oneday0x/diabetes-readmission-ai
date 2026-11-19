models <- c("LogReg", "EBM", "GradBoost", "RandomForest")
measures <- c("auroc_macro","auprc_macro","f1_macro","ppv_macro","tpr_macro",
              "auroc_micro","auprc_micro","f1_micro","brier",
              "auroc_weighted","auprc_weighted","f1_weighted","ppv_micro","ppv_weighted","tpr_micro","tpr_weighted")
raw <- read.csv("experiment1/results_measures_4models.csv")
raw <- raw[order(raw[[1]], raw[[2]]), ]
K <- 5; Rr <- 20; n <- K * Rr; ratio <- 1 / (K - 1)
ci <- function(x) {
  blocks <- colMeans(matrix(x, nrow = K))          # 5 consecutive folds = 1 block
  se_naive <- sd(blocks) / sqrt(Rr)
  se_nb <- sqrt((1 / n + ratio) * var(x))
  c(mean(x), qt(0.975, Rr - 1) * se_naive, qt(0.975, n - 1) * se_nb)
}
pyM <- read.csv("experiment1/ci_models_4models.csv")
pyD <- read.csv("experiment1/ci_differences_4models.csv")
dM <- c(); dD <- c(); flips <- 0
for (m in measures) {
  sign <- ifelse(m == "brier", -1, 1)
  S <- lapply(models, function(mo) raw[raw$model == mo, m]); names(S) <- models
  for (mo in models) {
    r <- ci(S[[mo]]); p <- pyM[pyM$measure == m & pyM$model == mo, ]
    dM <- c(dM, abs(r - c(p$mean, p$halfwidth_naive_20blocks, p$halfwidth_nadeau_bengio)))
  }
  for (a in 1:3) for (b in (a + 1):4) {
    d <- sign * (S[[a]] - S[[b]]); r <- ci(d)
    p <- pyD[pyD$measure == m & pyD$pair == paste(models[a], "vs", models[b]), ]
    dD <- c(dD, abs(c(r[1] - r[2], r[1] + r[2], r[1] - r[3], r[1] + r[3]) - c(p$naive_low, p$naive_high, p$nb_low, p$nb_high)))
    flips <- flips + (((r[1] - r[3] > 0) || (r[1] + r[3] < 0)) != (p$nb_interval_excludes_0 == "True"))
  }
}
cat("max difference, per-model table (mean, both half-widths):", max(dM), "\n")
cat("max difference, interval limits of the differences     :", max(dD), "\n")
cat("pairs where 'excludes 0' differs between Python and R  :", flips, "\n")