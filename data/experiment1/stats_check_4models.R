# stats_check_4models.R
# Independent check (Friedman + paired Wilcoxon with Holm correction) for 4 models.
# Input: one CSV per measure in the folder "matrices4": 20 blocks (rows) x 4 models (columns).
# Run from the folder that contains "matrices4":  Rscript stats_check_4models.R

models <- c("LogReg", "EBM", "GradBoost", "RandomForest")
pairs  <- combn(models, 2, simplify = FALSE)     # all 6 pairs
files  <- sort(list.files("matrices4", pattern = "\\.csv$", full.names = TRUE))

results <- data.frame()
for (f in files) {
  measure <- sub("\\.csv$", "", basename(f))
  m <- read.csv(f, row.names = 1, check.names = FALSE)
  m <- m[, models]

  fr <- friedman.test(as.matrix(m))

  raw <- sapply(pairs, function(p) {
    suppressWarnings(wilcox.test(m[[p[1]]], m[[p[2]]], paired = TRUE, exact = TRUE)$p.value)
  })
  adj <- p.adjust(raw, method = "holm")

  row <- data.frame(measure = measure,
                    friedman_chi2 = unname(fr$statistic),
                    friedman_p = fr$p.value)
  for (i in seq_along(pairs)) {
    nm <- paste(pairs[[i]], collapse = "-")
    row[[paste(nm, "raw")]]  <- raw[i]
    row[[paste(nm, "holm")]] <- adj[i]
  }
  results <- rbind(results, row)
}

write.csv(results, "friedman_wilcoxon_R_4models.csv", row.names = FALSE)

shown <- results[, c("measure", "friedman_chi2", "friedman_p",
                     grep("holm", names(results), value = TRUE))]
shown$friedman_chi2 <- round(shown$friedman_chi2, 1)
for (col in setdiff(names(shown), c("measure", "friedman_chi2")))
  shown[[col]] <- formatC(shown[[col]], format = "e", digits = 1)
print(shown, row.names = FALSE)

if (file.exists("friedman_wilcoxon_python_4models.csv")) {
  py <- read.csv("friedman_wilcoxon_python_4models.csv", check.names = FALSE)
  py <- py[match(results$measure, py$measure), ]
  cols <- setdiff(names(results), "measure")
  diffs <- sapply(cols, function(cn) max(abs(results[[cn]] - py[[cn]])))
  cat("\nOverall largest absolute difference between R and Python:",
      formatC(max(diffs), format = "e", digits = 1), "\n")
} else {
  cat("\nfriedman_wilcoxon_python_4models.csv not found, so no comparison was made.\n")
}