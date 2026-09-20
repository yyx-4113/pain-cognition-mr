suppressMessages(library(ieugwasr))
fs <- ls("package:ieugwasr")
pat <- c("clump", "gwas", "assoc", "extract", "harmon", "tophits", "ld")
keep <- fs[grepl(paste(pat, collapse = "|"), fs, ignore.case = TRUE)]
writeLines(keep, "analysis/_ieugwasr_fns.txt")
writeLines(paste("version:", as.character(packageVersion("ieugwasr"))), "analysis/_ieugwasr_ver.txt")
cat("WROTE", length(keep), "functions\n")
