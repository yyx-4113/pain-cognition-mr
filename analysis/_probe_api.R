suppressMessages({ library(ieugwasr) })
ROOT <- getwd()
jwt <- file.path(ROOT, "..", "JWT.txt")
if (!file.exists(jwt)) jwt <- file.path(ROOT, "JWT.txt")
Sys.setenv(OPENGWAS_JWT = trimws(readLines(jwt, n = 1)[1]))
options(ieugwasr.api_root = "https://api.opengwas.io/api")

cl <- tryCatch(readRDS("data/derived/_mcp_clumped.rds"), error = function(e) NULL)
if (is.null(cl)) { cat("NO_CLUMPED_RDS\n"); quit(status = 1) }
cat("clumped instruments:", nrow(cl), "\n")

for (id in c("ieu-a-297", "ieu-b-2")) {
  r <- tryCatch(associations(cl$rsid, id, align_alleles = 0, proxies = 0),
               error = function(e) paste("ERR:", conditionMessage(e)))
  if (is.character(r)) { cat(sprintf("%s -> %s\n", id, r)); next }
  cat(sprintf("%s -> rows=%d cols=%s\n", id, nrow(r),
              paste(names(r), collapse = "|")))
}
