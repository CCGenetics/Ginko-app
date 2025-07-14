# app/scripts/wrappers/step1_quality_check.R

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 3) {
  stop("Usage: Rscript step1_quality_check.R <input_csv> <output_dir> <keep_to_check: TRUE|FALSE>")
}

input_csv     <- args[1]
output_dir    <- args[2]
keep_to_check <- as.logical(args[3])

if (!file.exists(input_csv)) stop(paste("Input file does not exist:", input_csv))
if (is.na(keep_to_check)) stop("keep_to_check must be TRUE or FALSE")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

log_path <- file.path(output_dir, "step1_wrapper.log")

log_line <- function(...) {
  msg <- paste0(..., collapse = "")
  cat(msg, "\n")
  cat(msg, "\n", file = log_path, append = TRUE)
}

log_line("=== Step1 wrapper start ===")
log_line("input_csv: ", input_csv)
log_line("output_dir: ", output_dir)
log_line("keep_to_check: ", keep_to_check)

# ---- best-effort locale (helps with string handling) ----------------------
try(Sys.setlocale("LC_ALL", "C.UTF-8"), silent = TRUE)
try(Sys.setlocale("LC_CTYPE", "C.UTF-8"), silent = TRUE)

# ---- ensure required packages exist ---------------------------------------
required <- c(
  "rmarkdown", "knitr",
  "tidyr", "dplyr", "magrittr", "stringr", "ggplot2",
  "utile.tools"
)

installed <- rownames(installed.packages())
to_install <- setdiff(required, installed)

if (length(to_install) > 0) {
  log_line("Installing packages: ", paste(to_install, collapse = ", "))
  install.packages(to_install, repos = "https://cloud.r-project.org")
}

suppressPackageStartupMessages(library(rmarkdown))
suppressPackageStartupMessages(library(knitr))
suppressPackageStartupMessages(library(magrittr))

# ---- locate original Rmd ---------------------------------------------------
rmd_orig <- file.path("scripts", "Ginko-Rfun", "1_Processing_raw_data_quality_test.Rmd")
if (!file.exists(rmd_orig)) {
  log_line("ERROR: Rmd not found: ", rmd_orig)
  quit(status = 1)
}

# ---- convert input CSV to UTF-8 (demo-stable) -----------------------------
# Many Kobo exports come with mixed encodings. We create a UTF-8 copy that
# avoids 'invalid multibyte string' errors during render.
input_utf8 <- file.path(output_dir, "00_raw_data_utf8.csv")

convert_ok <- TRUE
tryCatch({
  raw_lines <- readLines(input_csv, warn = FALSE)

  # Try common legacy encodings -> UTF-8. Use sub="byte" to keep unknown bytes.
  # We prefer Windows-1252 first (common for European quotes/dashes), then latin1.
  conv1 <- iconv(raw_lines, from = "WINDOWS-1252", to = "UTF-8", sub = "byte")
  if (any(is.na(conv1))) {
    conv2 <- iconv(raw_lines, from = "latin1", to = "UTF-8", sub = "byte")
    if (any(is.na(conv2))) {
      # last resort: assume already UTF-8 but with issues; keep bytes
      conv2 <- iconv(raw_lines, from = "UTF-8", to = "UTF-8", sub = "byte")
    }
    writeLines(conv2, input_utf8, useBytes = TRUE)
  } else {
    writeLines(conv1, input_utf8, useBytes = TRUE)
  }

  log_line("Wrote UTF-8 copy: ", input_utf8)
}, error = function(e) {
  convert_ok <<- FALSE
  log_line("ERROR converting input to UTF-8: ", conditionMessage(e))
})

if (!convert_ok || !file.exists(input_utf8)) {
  log_line("ERROR: UTF-8 conversion failed, cannot continue.")
  quit(status = 1)
}

# ---- patch Rmd (override kobo_file and keep_to_check) ---------------------
rmd_patched <- file.path(output_dir, "1_Processing_raw_data_quality_test.PATCHED.Rmd")

rmd_lines <- readLines(rmd_orig, warn = FALSE)

kobo_line <- paste0('kobo_file="', normalizePath(input_utf8, winslash = "/", mustWork = TRUE), '"')
keep_line <- paste0("keep_to_check=", ifelse(keep_to_check, "TRUE", "FALSE"))

rmd_lines <- gsub("^\\s*kobo_file\\s*=\\s*.*$", kobo_line, rmd_lines, perl = TRUE)
rmd_lines <- gsub("^\\s*keep_to_check\\s*=\\s*.*$", keep_line, rmd_lines, perl = TRUE)

writeLines(rmd_lines, rmd_patched)
log_line("Patched Rmd written: ", rmd_patched)
log_line("Patched kobo_file line: ", kobo_line)
log_line("Patched keep_to_check line: ", keep_line)

# ---- render outputs into output_dir ---------------------------------------
old_wd <- getwd()
setwd(output_dir)
on.exit(setwd(old_wd), add = TRUE)

ok <- TRUE
tryCatch({
  log_line("Rendering patched Rmd...")

  rmarkdown::render(
    input = normalizePath(rmd_patched, winslash = "/", mustWork = TRUE),
    output_format = "html_document",
    output_file = "step1_quality_check_report.html",
    quiet = FALSE
  )

  log_line("Render finished.")
}, error = function(e) {
  ok <<- FALSE
  log_line("ERROR during render: ", conditionMessage(e))
})

report_path  <- file.path(output_dir, "step1_quality_check_report.html")
tocheck_path <- file.path(output_dir, "kobo_output_tocheck.csv")
clean_path   <- file.path(output_dir, "kobo_output_clean.csv")

log_line("Report exists: ", file.exists(report_path))
log_line("To-check CSV exists: ", file.exists(tocheck_path))
log_line("Clean CSV exists: ", file.exists(clean_path))
log_line("Log file: ", log_path)
log_line("=== Step1 wrapper end ===")

if (!ok) quit(status = 1)
if (!file.exists(report_path)) quit(status = 1)

quit(status = 0)
