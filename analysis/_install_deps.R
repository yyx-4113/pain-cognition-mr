options(Ncpus = 4, repos = "https://cloud.r-project.org")
pkgs <- c("TwoSampleMR", "ieugwasr", "lme4", "rms", "mice", "tableone",
          "ggplot2", "cmprsk", "nhanesA", "readxl")
inst <- installed.packages()[, "Package"]
todo <- setdiff(pkgs, inst)
cat("Installing:", paste(todo, collapse = ", "), "\n")
if (length(todo) > 0) {
  install.packages(todo, ask = FALSE, dependencies = c("Depends", "Imports", "LinkingTo"))
}
cat("DONE-INSTALL\n")
final <- installed.packages()[, "Package"]
cat("STILL-MISSING:", paste(setdiff(pkgs, final), collapse = ", "), "\n")
