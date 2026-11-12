# stats_check.R
# Independent check of the statistical tests (Friedman + paired Wilcoxon with Holm correction).
# Input: one CSV per measure in the folder "matrices", each a matrix with
#        20 blocks (rows) and 3 models (columns).
# Run from the folder that contains "matrices":  Rscript stats_check.R

files  <- sort(list.files("matrices", pattern = "\\.csv$", full.names = TRUE))
pairs  <- list(c("LogReg", "GradBoost"),
               c("LogReg", "RandomForest"),
               c("GradBoost", "RandomForest"))

results <- data.frame()
for (f in files) {
  measure <- sub("\\.csv$", "", basename(f))
  m <- read.csv(f, row.names = 1, check.names = FALSE)
  m <- m[, c("LogReg", "GradBoost", "RandomForest")]

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

write.csv(results, "friedman_wilcoxon_R.csv", row.names = FALSE)

# Print the results with p-values in scientific notation
shown <- results[, c("measure", "friedman_chi2", "friedman_p",
                     grep("holm", names(results), value = TRUE))]
for (col in names(shown)[-1]) shown[[col]] <- formatC(shown[[col]], format = "e", digits = 1)
print(shown, row.names = FALSE)

# Compare with the Python results
if (file.exists("friedman_wilcoxon_python.csv")) {
  py <- read.csv("friedman_wilcoxon_python.csv", check.names = FALSE)
  py <- py[match(results$measure, py$measure), ]
  cols <- setdiff(names(results), "measure")
  diffs <- sapply(cols, function(cn) max(abs(results[[cn]] - py[[cn]])))
  cat("\nLargest absolute difference between R and Python, per column:\n")
  print(formatC(diffs, format = "e", digits = 1), quote = FALSE)
  cat("\nOverall largest difference:", formatC(max(diffs), format = "e", digits = 1), "\n")
} else {
  cat("\nfriedman_wilcoxon_python.csv not found, so no comparison was made.\n")
}