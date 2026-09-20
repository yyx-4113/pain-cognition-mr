suppressMessages({ library(data.table); library(ieugwasr) })
ROOT <- getwd()
jwt <- file.path(ROOT, "..", "JWT.txt"); if (!file.exists(jwt)) jwt <- file.path(ROOT, "JWT.txt")
Sys.setenv(OPENGWAS_JWT = trimws(readLines(jwt, n = 1)[1]))
options(ieugwasr.api_root = "https://api.opengwas.io/api")
cl <- readRDS("data/derived/_mcp_clumped.rds")
ids <- c("ieu-a-297", "ieu-b-2", "ieu-a-298")
for (id in ids) {
  for (pr in c(0, 1)) {
    r <- tryCatch(associations(cl$rsid, id, align_alleles = 0, proxies = pr), error = function(e) NULL)
    n <- if (is.null(r)) 0 else nrow(r)
    cat(sprintf("%s proxies=%d -> rows=%d\n", id, pr, n))
    if (!is.null(r) && nrow(r) > 0) { cat("  cols:", paste(names(r), collapse = "|"), "\n"); break }
  }
}
cat("ADTEST_DONE\n")
