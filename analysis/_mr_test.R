suppressMessages({
  library(data.table)
  library(ieugwasr)
})
ROOT <- getwd()
jwt_path <- file.path(ROOT, "JWT.txt"); if (!file.exists(jwt_path)) jwt_path <- file.path(ROOT, "..", "JWT.txt")
Sys.setenv(OPENGWAS_JWT = trimws(readLines(jwt_path, n = 1)[1]))
options(ieugwasr.api_root = "https://api.opengwas.io/api")

MCP <- "data/raw/chronic_pain-bgen.stats.gz"
CACHE <- "data/derived/_mcp_sig.rds"
if (!file.exists(CACHE)) {
  cat("Reading MCP (full)...\n")
  dt <- fread(MCP, sep = "\t", select = c("SNP","CHR","BP","ALLELE1","ALLELE0","P_LINREG","BETA","SE"))
  sig <- dt[P_LINREG < 5e-8]
  sig <- sig[, .(rsid = SNP, chr = CHR, bp = BP, a1 = ALLELE1, a0 = ALLELE0, pval = P_LINREG, beta = BETA, se = SE)]
  saveRDS(sig, CACHE)
  cat("  cached significant SNPs:", nrow(sig), "->", CACHE, "\n")
} else {
  sig <- readRDS(CACHE)
  cat("Loaded cached significant SNPs:", nrow(sig), "\n")
}

cat("Clumping...\n")
cl <- tryCatch(ld_clump(sig[, .(rsid, pval)], pop = "EUR"),
               error = function(e){ cat("CLUMP_ERR:", conditionMessage(e), "\n"); NULL })
if (!is.null(cl)) {
  cat("  clumped loci SNPs:", nrow(cl), "\n")
  writeLines(as.character(cl$rsid), "analysis/_clumped_snps.txt")
  cat("Extracting outcome ebi-a-GCST006572 for clumped SNPs...\n")
  out <- tryCatch(associations(cl$rsid, "ebi-a-GCST006572", align_alleles = 0),
                  error = function(e){ cat("ASSOC_ERR:", conditionMessage(e), "\n"); NULL })
  if (!is.null(out)) {
    cat("  outcome rows:", nrow(out), "\n")
    cat("  outcome cols:", paste(names(out), collapse = "|"), "\n")
    print(head(out[, 1:min(10, ncol(out))]))
  }
} else {
  cat("No clump results.\n")
}
cat("TEST_DONE\n")
