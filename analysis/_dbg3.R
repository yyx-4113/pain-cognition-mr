suppressMessages(library(data.table))
h <- fread("data/derived/mr_harmonized_cog.csv")
bx <- h$beta; by <- h$beta_out_adj; sey <- h$se_out
w <- 1/sey^2; wt <- w*bx^2; ord <- order(wt, decreasing=TRUE); cum <- cumsum(wt[ord])/sum(wt)
wr <- (by/bx)[ord]   # Wald ratios ordered by weight
cat("Wald ratio distribution (ordered by weight desc), cum weight:\n")
for (i in 1:length(wr)) cat(sprintf("%2d  wr=%7.3f  bx=%8.4f  cum=%.3f\n", i, wr[i], bx[ord][i], cum[i]))
cat("\nidx where cum>=0.5:", which(cum>=0.5)[1], " wr there:", wr[which(cum>=0.5)[1]], "\n")
cat("median of all wr:", median(wr), " mean:", mean(wr), "\n")
