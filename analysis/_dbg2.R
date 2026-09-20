suppressMessages({ library(data.table); library(ieugwasr) })
ROOT <- getwd()
jwt_path <- file.path(ROOT, "JWT.txt"); if (!file.exists(jwt_path)) jwt_path <- file.path(ROOT, "..", "JWT.txt")
Sys.setenv(OPENGWAS_JWT = trimws(readLines(jwt_path, n = 1)[1])); options(ieugwasr.api_root = "https://api.opengwas.io/api")

# 1) correct WMed on cog harmonized
h <- fread("data/derived/mr_harmonized_cog.csv")
bx <- h$beta; by <- h$beta_out_adj; sey <- h$se_out
w <- 1/sey^2; wt <- w*bx^2; ord <- order(wt, decreasing=TRUE); cum <- cumsum(wt[ord])/sum(wt); idx <- which(cum>=0.5)[1]
bmed <- (by/bx)[ord][idx]
cat("CORRECTED WMed:", bmed, " (idx", idx, ")\n")

# 2) test AD extraction
cl <- readRDS("data/derived/_mcp_clumped.rds")
cat("Testing associations for ieu-a-298 ...\n")
res <- tryCatch(associations(cl$rsid, "ieu-a-298", align_alleles=0, proxies=0),
               error=function(e){ cat("ERR:", conditionMessage(e), "\n"); NULL })
if (!is.null(res)) { cat("OK rows:", nrow(res), " cols:", paste(names(res),collapse="|"), "\n") }
else {
  # retry with proxies=1
  res2 <- tryCatch(associations(cl$rsid, "ieu-a-298", align_alleles=0, proxies=1),
                   error=function(e){ cat("ERR2:", conditionMessage(e), "\n"); NULL })
  if (!is.null(res2)) cat("OK(proxies=1) rows:", nrow(res2), "\n") else cat("still null\n")
}
