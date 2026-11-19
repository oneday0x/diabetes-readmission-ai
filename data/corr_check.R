res <- read.csv("experiment1/multiple_correction_comparison_4models.csv")
shaffer <- function(p) { o <- order(p); a <- cummax(c(6, 3, 3, 3, 2, 1) * p[o]); out <- numeric(6); out[o] <- pmin(1, a); out }
finner <- function(p) { m <- length(p); o <- order(p); a <- cummax(1 - (1 - p[o])^(m / seq_len(m))); out <- numeric(m); out[o] <- pmin(1, a); out }
# Bergmann-Hommel: the 14 sets of pair hypotheses that can be true together, written out by hand.
# Pairs in order: 1=(A,B) 2=(A,C) 3=(A,D) 4=(B,C) 5=(B,D) 6=(C,D)  with A=LogReg, B=EBM, C=GradBoost, D=RandomForest
sets <- list(1, 2, 3, 4, 5, 6,                     # one pair equal, all others different
             c(1, 6), c(2, 5), c(3, 4),            # two separate equal pairs
             c(1, 2, 4), c(1, 3, 5), c(2, 3, 6), c(4, 5, 6),   # three models equal (triangle)
             1:6)                                  # all four equal
bh <- function(p) {
  adj <- numeric(6)
  for (s in sets) { v <- min(1, length(s) * min(p[s])); adj[s] <- pmax(adj[s], v) }
  adj
}
d <- c(holm = 0, hochberg = 0, hommel = 0, finner = 0, shaffer = 0, bergmann_hommel = 0)
for (me in unique(res$measure)) {
  s <- res[res$measure == me, ]; p <- s$raw_p
  d["holm"]            <- max(d["holm"],            abs(s$holm     - p.adjust(p, "holm")))
  d["hochberg"]        <- max(d["hochberg"],        abs(s$hochberg - p.adjust(p, "hochberg")))
  d["hommel"]          <- max(d["hommel"],          abs(s$hommel   - p.adjust(p, "hommel")))
  d["finner"]          <- max(d["finner"],          abs(s$finner   - finner(p)))
  d["shaffer"]         <- max(d["shaffer"],         abs(s$shaffer  - shaffer(p)))
  d["bergmann_hommel"] <- max(d["bergmann_hommel"], abs(s$bergmann_hommel - bh(p)))
}
cat("max |Python - R| per procedure:\n"); print(d)
sig <- sapply(c("holm", "hochberg", "hommel", "finner", "shaffer", "bergmann_hommel"), function(k) sum(res[[k]] < 0.05))
cat("significant pairs at 0.05 (of", nrow(res), "):\n"); print(sig)