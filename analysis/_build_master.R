suppressMessages(library(data.table))
DER <- "data/derived"
fwd <- fread(file.path(DER, "mr_forward_results_corrected.csv"))
adr <- fread(file.path(DER, "mr_ad_reverse_results.csv"))

# unify schemas (both share the IVW/Egger/WMed/Cochran/LOO columns)
master <- rbindlist(list(fwd, adr), fill = TRUE)

# add human-readable direction + interpretation
dir_label <- function(o) {
  if (o == "MCP->Cognitive_performance") return("MCP -> cognition")
  if (o == "MCP->All_cause_dementia")    return("MCP -> all-cause dementia")
  if (o == "ad_igap2")                   return("MCP -> AD (IGAP ieu-a-297)")
  if (o == "ad_bennevis")                return("MCP -> AD (Ben Nevis ieu-b-2)")
  if (o == "reverse_cog_pain")           return("cognition -> MCP (reverse)")
  o
}
sig <- function(p) ifelse(is.na(p), "", ifelse(p < 0.001, "<0.001", as.character(round(p, 3))))
master[, direction := sapply(outcome, dir_label)]
master[, IVW_p_txt := sig(IVW_p_fixed)]
master[, Egger_int_p_txt := sig(Egger_int_p)]
master[, Cochran_p_txt := sig(Cochran_p)]
master[, interpretation := fcase(
  outcome == "MCP->Cognitive_performance", "Strong evidence: genetically-predicted multisite chronic pain lowers cognitive performance",
  outcome == "MCP->All_cause_dementia",    "Null: no evidence MCP raises all-cause dementia",
  outcome == "ad_igap2",                   "Significant: MCP raises AD risk (IGAP); needs replication",
  outcome == "ad_bennevis",                "Null: Ben Nevis AD GWAS does not replicate",
  outcome == "reverse_cog_pain",           "Both directions significant -> directional causality uncertain; possible pleiotropy/shared architecture"
)]

keep <- c("direction","n_snps","IVW_beta","IVW_se_fixed","IVW_p_txt","IVW_beta_RE","IVW_se_RE",
          "Egger_beta","Egger_int_p_txt","WMed_beta","WMed_se","Cochran_Q","Cochran_p_txt",
          "LOO_min","LOO_max","interpretation")
out <- master[, ..keep]
fwrite(out, file.path(DER, "mr_master_results.csv"))
cat("Wrote data/derived/mr_master_results.csv\n")
print(out)
