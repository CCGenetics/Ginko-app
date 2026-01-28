# app/scripts/wrappers/step4_report.R

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 3) {
  stop("Usage: Rscript step4_report.R <input_dir> <output_dir> <country_name>")
}

input_dir    <- args[1]
output_dir   <- args[2]
country_name <- args[3]

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

log_path <- file.path(output_dir, "step4_wrapper.log")

log_line <- function(...) {
  msg <- paste0(..., collapse = "")
  cat(msg, "\n")
  cat(msg, "\n", file = log_path, append = TRUE)
}

log_line("=== Step4 wrapper start ===")
log_line("input_dir: ", input_dir)
log_line("output_dir: ", output_dir)
log_line("country_name: ", country_name)

# ---- check input files exist -----------------
indicators_full_file <- file.path(input_dir, "indicators_full.csv")
indNe_file <- file.path(input_dir, "indNe_data.csv")

if (!file.exists(indicators_full_file)) stop(paste("Missing:", indicators_full_file))
if (!file.exists(indNe_file)) stop(paste("Missing:", indNe_file))

# ---- best-effort locale ----------------------
try(Sys.setlocale("LC_ALL", "C.UTF-8"), silent = TRUE)
try(Sys.setlocale("LC_CTYPE", "C.UTF-8"), silent = TRUE)

# ---- ensure required packages exist ----------
required <- c(
  "rmarkdown", "knitr",
  "tidyr", "dplyr", "magrittr", "ggplot2", "viridis"
)

installed <- rownames(installed.packages())
to_install <- setdiff(required, installed)

if (length(to_install) > 0) {
  log_line("Installing packages: ", paste(to_install, collapse = ", "))
  install.packages(to_install, repos = "https://cloud.r-project.org")
}

suppressPackageStartupMessages({
  library(rmarkdown)
  library(knitr)
  library(magrittr)
})

# ---- locate original Rmd ---------------------
rmd_orig <- file.path("scripts", "Ginko-Rfun", "4_country_report.Rmd")
if (!file.exists(rmd_orig)) {
  log_line("ERROR: Rmd not found: ", rmd_orig)
  quit(status = 1)
}

# ---- copy input files to output_dir (Rmd expects them in working dir) ----
file.copy(indicators_full_file, file.path(output_dir, "indicators_full.csv"), overwrite = TRUE)
file.copy(indNe_file, file.path(output_dir, "indNe_data.csv"), overwrite = TRUE)
log_line("Copied input files to output_dir")

# ---- patch Rmd (override desired_country) ----
rmd_patched <- file.path(output_dir, "4_country_report.PATCHED.Rmd")

rmd_lines <- readLines(rmd_orig, warn = FALSE)

# Find and replace the desired_country line
# The original has: desired_country<-"mexico"
country_line <- paste0('desired_country<-"', country_name, '"')
rmd_lines <- gsub(
  '^\\s*desired_country\\s*<-\\s*"[^"]*"',
  country_line,
  rmd_lines,
  perl = TRUE
)

writeLines(rmd_lines, rmd_patched)
log_line("Patched Rmd written: ", rmd_patched)
log_line("Patched desired_country line: ", country_line)

# ---- render report ---------------------------
old_wd <- getwd()
setwd(output_dir)
on.exit(setwd(old_wd), add = TRUE)

ok <- TRUE
tryCatch({
  log_line("Rendering country report...")

  rmarkdown::render(
    input = normalizePath(rmd_patched, winslash = "/", mustWork = TRUE),
    output_format = "html_document",
    output_file = "country_report.html",
    quiet = FALSE
  )

  log_line("Render finished.")
}, error = function(e) {
  ok <<- FALSE
  log_line("ERROR during render: ", conditionMessage(e))
})

report_path <- file.path(output_dir, "country_report.html")

log_line("Report exists: ", file.exists(report_path))
log_line("Log file: ", log_path)
log_line("=== Step4 wrapper end ===")

if (!ok) quit(status = 1)
if (!file.exists(report_path)) quit(status = 1)

quit(status = 0)
