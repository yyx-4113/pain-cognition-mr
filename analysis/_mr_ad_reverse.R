#!/usr/bin/env Rscript
# _mr_ad_reverse.R  -- targeted: MCP->AD (alt IDs) + reverse cognition->MCP
# Uses cached clumped MCP instruments; relative paths (R fread handles getwd() Chinese path).
suppressMessages({ library(data.table); library(ieugwasr) })
ROOT <- getwd()
jwt_path <- file.path(ROOT, "JWT.txt"); if (!file.exists(jwt_path)) jwt_path <- file.path(ROOT, "..", "JWT.txt")
if (!file.exists(jwt_path)) stop("JWT.txt not found")
Sys.setenv(OPENGWAS_JWT = trimws(readLines(jwt_path, n = 1)[1]))
options(ieugwasr.api_root = "https://api.opengwas.io/api")

MCP_FILE  <- "data/raw/chronic_pain-bgen.stats.gz"
SIG_CACHE <- "data/derived/_mcp_sig.rds"
CL_CACHE  <- "data/derived/_mcp_clumped.rds"
DER       <- "data/derived"

## ---- estimators (corrected: WMed = median of per-SNP Wald ratios) ----------
ivw_fixed <- function(bx,by,sey){ w<-1/sey^2; b<-sum(w*bx*by)/sum(w*bx^2); se<-1/sqrt(sum(w*bx^2)); list(b=b,se=se) }
cochran_q <- function(bx,by,sey,b){ w<-1/sey^2; Q<-sum(w*(by-b*bx)^2); df<-length(bx)-1; p<-pchisq(Q,df,lower.tail=FALSE); list(Q=Q,df=df,p=p) }
ivw_re <- function(bx,by,sey,bf){ w<-1/sey^2; Q<-sum(w*(by-bf*bx)^2); df<-length(bx)-1; tau2<-max(0,(Q-df)/(sum(w)-sum(w^2)/sum(w))); w2<-1/(1/w+tau2); b<-sum(w2*bx*by)/sum(w2*bx^2); se<-1/sqrt(sum(w2*bx^2)); list(b=b,se=se,tau2=tau2) }
egger <- function(bx,by,sey){ w<-1/sey^2; WX<-sum(w*bx);WY<-sum(w*by);WXX<-sum(w*bx^2);WXY<-sum(w*bx*by);W<-sum(w); denom<-W*WXX-WX^2; b<-(W*WXY-WX*WY)/denom; a<-(WY-b*WX)/W; se_b<-sqrt(W/denom); se_a<-sqrt(WXX/denom); list(slope=b,se_slope=se_b,intercept=a,se_int=se_a,p_int=2*pnorm(-abs(a/se_a))) }
wmedian <- function(bx,by,sex,sey){ g<-by/bx; se_g<-abs(g)*sqrt((sey/by)^2+(sex/bx)^2); w<-1/se_g^2; ord<-order(g); cum<-cumsum(w[ord])/sum(w); idx<-which(cum>=0.5)[1]; list(b=g[ord][idx],se=sqrt(1/sum(w[ord][1:idx]))) }
loo <- function(bx,by,sey){ n<-length(bx); bs<-numeric(n); for(i in seq_len(n)){ ii<-setdiff(seq_len(n),i); bs[i]<-ivw_fixed(bx[ii],by[ii],sey[ii])$b }; list(min=min(bs),max=max(bs),flips=sum(sign(bs)!=sign(bs[1]))) }

norm_cols <- function(df){ nm<-tolower(names(df)); pick<-function(opts){for(o in opts){j<-which(nm==o)[1];if(!is.na(j))return(names(df)[j])};NA_character_}; list(snp=pick(c("variant","rsid","snp","id")),ea=pick(c("ea","effect_allele","effectallele")),oa=pick(c("oa","nea","other_allele","non_effect_allele")),beta=pick(c("beta","b")),se=pick(c("se","stderr","standard_error")),p=pick(c("p","pval","p_value"))) }

harmonize <- function(exp,out){
  c<-norm_cols(out)
  o<-data.table(rsid=out[[c$snp]],oa_eff=out[[c$ea]],oa_oth=out[[c$oa]],beta_out=as.numeric(out[[c$beta]]),se_out=as.numeric(out[[c$se]]),p_out=as.numeric(out[[c$p]]))
  m<-merge(exp,o,by="rsid",all=FALSE)
  keep<-m[!is.na(beta_out)&!is.na(se_out)&se_out>0&!is.na(beta)&!is.na(se)&se>0]
  s<-rep(0,nrow(keep))
  s[keep$a1==keep$oa_eff&keep$a0==keep$oa_oth]<-0
  s[keep$a1==keep$oa_oth&keep$a0==keep$oa_eff]<-1
  keep$beta_out_adj<-ifelse(s==1,-keep$beta_out,keep$beta_out)
  keep$orientation<-ifelse(s==1,"flipped","same")
  keep
}

analyze <- function(bx,by,sex,sey,label){
  iv<-ivw_fixed(bx,by,sey); q<-cochran_q(bx,by,sey,iv$b); re<-ivw_re(bx,by,sey,iv$b); eg<-egger(bx,by,sey); wm<-wmedian(bx,by,sex,sey); l<-loo(bx,by,sey)
  data.frame(outcome=label,n_snps=length(bx),
    IVW_beta=round(iv$b,4),IVW_se_fixed=round(iv$se,4),IVW_p_fixed=signif(2*pnorm(-abs(iv$b/iv$se)),3),
    IVW_beta_RE=round(re$b,4),IVW_se_RE=round(re$se,4),
    Egger_beta=round(eg$slope,4),Egger_se=round(eg$se_slope,4),Egger_int=round(eg$intercept,6),Egger_int_p=round(eg$p_int,4),
    WMed_beta=round(wm$b,4),WMed_se=round(wm$se,4),
    Cochran_Q=round(q$Q,2),Cochran_df=q$df,Cochran_p=signif(q$p,3),
    LOO_min=round(l$min,4),LOO_max=round(l$max,4),LOO_flips=l$flips,stringsAsFactors=FALSE)
}

get_assoc <- function(variants,id,align=0,tries=3){ for(i in seq_len(tries)){ a<-tryCatch(associations(variants,id,align_alleles=align,proxies=0),error=function(e)NULL); if(!is.null(a)&&nrow(a)>0)return(a); Sys.sleep(2) }; NULL }

## ---- load cached exposure instruments --------------------------------------
sig<-readRDS(SIG_CACHE); cl<-readRDS(CL_CACHE)
exp_dat<-sig[rsid %in% cl$rsid]
cat("Exposure instruments (MCP):", nrow(exp_dat), "\n")

## ---- AD alt IDs -------------------------------------------------------------
ad_ids <- list(
  ad_igap2   = list(id="ieu-a-297", label="AD (IGAP ieu-a-297)"),
  ad_bennevis= list(id="ieu-b-2",   label="AD (Ben Nevis ieu-b-2)")
)
rows<-list()
for(nm in names(ad_ids)){
  cat("\n=== MCP ->", ad_ids[[nm]]$label, "===\n")
  out<-get_assoc(cl$rsid, ad_ids[[nm]]$id)
  if(is.null(out)){ cat("  no data returned\n"); next }
  h<-tryCatch(harmonize(exp_dat,out),error=function(e){cat("  harmonize err:",conditionMessage(e),"\n");NULL})
  if(is.null(h)||nrow(h)==0){ cat("  0 harmonized SNPs\n"); next }
  cat("  harmonized SNPs:", nrow(h), "\n")
  fwrite(h, file.path(DER, paste0("mr_harmonized_", nm, ".csv")))
  rows[[nm]]<-analyze(h$beta,h$beta_out_adj,h$se,h$se_out, nm)
  print(rows[[nm]])
}

## ---- reverse MR: cognition -> MCP ------------------------------------------
cat("\n=== Reverse: Cognitive performance -> MCP ===\n")
cog_inst<-as.data.table(tophits("ebi-a-GCST006572", pval=5e-8))
cnm<-tolower(names(cog_inst))
rs_col<-c("variant","rsid","snp")[which(c("variant","rsid","snp")%in%cnm)[1]]
pv_col<-c("pval","p","pval.exposure")[which(c("pval","p","pval.exposure")%in%cnm)[1]]
cog_cl<-ld_clump(cog_inst[,.(rsid=cog_inst[[rs_col]], pval=as.numeric(cog_inst[[pv_col]]))], pop="EUR")
cat("  cognitive instruments (clumped):", nrow(cog_cl), "\n")
cog_exp0<-get_assoc(cog_cl$rsid, "ebi-a-GCST006572", align=0)
cc<-norm_cols(cog_exp0)
cog_exp<-data.table(rsid=cog_exp0[[cc$snp]], a1=cog_exp0[[cc$ea]], a0=cog_exp0[[cc$oa]],
                    beta=as.numeric(cog_exp0[[cc$beta]]), se=as.numeric(cog_exp0[[cc$se]]))
cat("  reading MCP for cognitive instruments (one-time)...\n")
mc<-fread(MCP_FILE, sep="\t", select=c("SNP","ALLELE1","ALLELE0","P_LINREG","BETA","SE"))
mc<-mc[SNP %in% cog_cl$rsid]
mh<-data.table(rsid=mc$SNP, oa_eff=mc$ALLELE1, oa_oth=mc$ALLELE0, beta_out=as.numeric(mc$BETA), se_out=as.numeric(mc$SE))
mh<-merge(cog_exp, mh, by="rsid")
mh<-mh[(mh$a1==mh$oa_eff & mh$a0==mh$oa_oth) | (mh$a1==mh$oa_oth & mh$a0==mh$oa_eff)]
mh$beta_out_adj<-ifelse(mh$a1==mh$oa_oth, -mh$beta_out, mh$beta_out)
cat("  reverse harmonized SNPs:", nrow(mh), "\n")
if(nrow(mh)>=3){
  rows[["reverse_cog_pain"]]<-analyze(mh$beta, mh$beta_out_adj, mh$se, mh$se_out, "reverse_cog_pain")
  print(rows[["reverse_cog_pain"]])
} else cat("  insufficient SNPs for reverse MR\n")

out<-do.call(rbind, rows)
fwrite(out, file.path(DER, "mr_ad_reverse_results.csv"))
cat("\nWrote data/derived/mr_ad_reverse_results.csv (", nrow(out), " rows )\nDONE\n")
