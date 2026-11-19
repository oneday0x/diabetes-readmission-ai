models <- c("LogReg", "EBM", "GradBoost", "RandomForest")
measures <- c("auroc_macro","auprc_macro","f1_macro","ppv_macro","tpr_macro",
              "auroc_micro","auprc_micro","f1_micro","brier",
              "auroc_weighted","auprc_weighted","f1_weighted","ppv_micro","ppv_weighted","tpr_micro","tpr_weighted")
py <- read.csv("results/experiment1/effect_sizes_ci_4models.csv")
pyW <- read.csv("results/experiment1/kendalls_w_4models.csv")
set.seed(1)
out <- list(); wout <- list()
for (m in measures) {
  M <- as.matrix(read.csv(paste0("results/experiment1/matrices4/", m, ".csv"))[, models])
  if (m == "brier") M <- -M
  # Kendall's W from the Friedman statistic: W = chi2 / (n * (k - 1))
  fr <- friedman.test(M)
  wout[[m]] <- data.frame(measure = m, W_R = unname(fr$statistic) / (nrow(M) * (ncol(M) - 1)))
  for (a in 1:3) for (b in (a + 1):4) {
    d <- M[, a] - M[, b]
    nz <- d[d != 0]
    rk <- rank(abs(nz))
    rb <- (sum(rk[nz > 0]) - sum(rk[nz < 0])) / sum(rk)
    bs <- replicate(10000, mean(sample(d, replace = TRUE)))
    q <- quantile(bs, c(0.025, 0.975))
    out[[length(out) + 1]] <- data.frame(measure = m, pair = paste(models[a], "vs", models[b]),
      mean_diff_R = mean(d), ci_low_R = q[[1]], ci_high_R = q[[2]],
      d_R = mean(d) / sd(d), rb_R = rb, wins_R = sum(d > 0))
  }
}
R <- do.call(rbind, out); WR <- do.call(rbind, wout)
J <- merge(py, R, by = c("measure", "pair"))
cat("rows compared:", nrow(J), "\n")
cat("max |mean_diff  Python - R| :", max(abs(J$mean_diff - J$mean_diff_R)), "\n")
cat("max |paired d   Python - R| :", max(abs(J$cohens_d_paired - J$d_R), na.rm = TRUE), "\n")
cat("max |rank-biserial Python - R|:", max(abs(J$rank_biserial - J$rb_R)), "\n")
cat("wins differ in rows          :", sum(J$wins_of_20 != J$wins_R), "\n")
cat("max |CI low  Python - R| (bootstrap, random) :", max(abs(J$ci_low - J$ci_low_R)), "\n")
cat("max |CI high Python - R| (bootstrap, random) :", max(abs(J$ci_high - J$ci_high_R)), "\n")
WJ <- merge(pyW, WR, by = "measure")
cat("max |Kendall W Python - R| (R uses tie correction):", max(abs(WJ$kendalls_W - WJ$W_R)), "\n")
print(WJ[abs(WJ$kendalls_W - WJ$W_R) > 1e-9, ])