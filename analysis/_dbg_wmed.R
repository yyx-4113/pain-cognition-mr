suppressMessages(library(data.table))
h <- fread("data/derived/mr_harmonized_cog.csv")
cat("n SNPs:", nrow(h), "\n")
bx <- h$beta; by <- h$beta_out_adj; sey <- h$se_out
cat("range beta_x:", range(bx), "  range beta_y:", range(by), "\n")
# IVW
w <- 1/sey^2
b_ivw <- sum(w*bx*by)/sum(w*bx^2)
cat("IVW:", b_ivw, "\n")
# Weighted median (Bowden) - careful
wt <- w * bx^2
ord <- order(wt, decreasing=TRUE)
cum <- cumsum(wt[ord])/sum(wt)
idx <- which(cum >= 0.5)[1]
cat("idx:", idx, " cum[idx]:", cum[idx], "\n")
cat("by[ord][idx]:", by[ord][idx], "\n")
cat("top5 ordered SNPs: beta_x, beta_y, cumwt:\n")
for (i in 1:5) cat(sprintf("  %d  bx=%.4f by=%.4f cum=%.3f\n", i, bx[ord][i], by[ord][i], cum[i]))
# Alternative weighted median (interpolated) suggested by Bowden: estimate is beta_y at median weight
# Also compute using the standard formula from 'MendelianRandomization' package logic:
# sort by abs(bx)/sey ; cumulative weight
cat("\n-- recompute with abs(bx)/sey weighting --\n")
wt2 <- abs(bx)/sey
o2 <- order(wt2, decreasing=TRUE)
c2 <- cumsum(wt2[o2])/sum(wt2)
i2 <- which(c2 >= 0.5)[1]
cat("idx2:", i2, " by:", by[o2][i2], "\n")
