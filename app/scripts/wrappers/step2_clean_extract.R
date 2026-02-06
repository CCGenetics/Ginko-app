# app/scripts/wrappers/step2_clean_extract.R
#
# Step 2 Wrapper: Clean & Extract Indicators Data
# Transforms cleaned Kobo data into indicator-specific datasets.
#
# Usage: Rscript step2_clean_extract.R <input_csv> <output_dir> <ratio>
#
# Outputs:
#   - indNe_data.csv: Data for Ne 500 indicator (population-level)
#   - indPM_data.csv: Data for PM indicator (taxon-level)
#   - indDNAbased_data.csv: Data for DNA-based indicator (taxon-level)
#   - metadata.csv: Taxon and assessment metadata

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 3) {
  stop("Usage: Rscript step2_clean_extract.R <input_csv> <output_dir> <ratio>")
}

input_csv  <- args[1]
output_dir <- args[2]
ratio      <- as.numeric(args[3])

if (!file.exists(input_csv)) stop(paste("Input file does not exist:", input_csv))
if (is.na(ratio) || ratio < 0 || ratio > 1) stop("ratio must be a number between 0 and 1")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

log_path <- file.path(output_dir, "step2_wrapper.log")

log_line <- function(...) {
  msg <- paste0(..., collapse = "")
  cat(msg, "\n")

  cat(msg, "\n", file = log_path, append = TRUE)
}

log_line("=== Step2 wrapper start ===")
log_line("input_csv: ", input_csv)
log_line("output_dir: ", output_dir)
log_line("ratio: ", ratio)

# ---- best-effort locale ----------------------
try(Sys.setlocale("LC_ALL", "C.UTF-8"), silent = TRUE)
try(Sys.setlocale("LC_CTYPE", "C.UTF-8"), silent = TRUE)

# ---- ensure required packages exist ----------
required <- c(
  "tidyr", "dplyr", "magrittr", "stringr", "utile.tools"
)

installed <- rownames(installed.packages())
to_install <- setdiff(required, installed)

if (length(to_install) > 0) {
  log_line("Installing packages: ", paste(to_install, collapse = ", "))
  install.packages(to_install, repos = "https://cloud.r-project.org")
}

suppressPackageStartupMessages({
  library(tidyr)
  library(dplyr)
  library(magrittr)
  library(stringr)
  library(utile.tools)
})

# ---- source Ginko-Rfun functions -------------
rfun_dir <- file.path("scripts", "Ginko-Rfun")

source(file.path(rfun_dir, "get_indicatorNe_data.R"))
source(file.path(rfun_dir, "get_indicatorPM_data.R"))
source(file.path(rfun_dir, "get_indicatorDNAbased_data.R"))
source(file.path(rfun_dir, "get_metadata.R"))
source(file.path(rfun_dir, "transform_to_Ne.R"))

log_line("Sourced Ginko-Rfun functions")

# ---- read input data -------------------------
log_line("Reading input file...")

kobo_clean <- tryCatch({
  read.csv(file = input_csv, header = TRUE, stringsAsFactors = FALSE)
}, error = function(e) {
  log_line("ERROR reading input CSV: ", conditionMessage(e))
  quit(status = 1)
})

log_line("Input file read successfully. Rows: ", nrow(kobo_clean), ", Cols: ", ncol(kobo_clean))

# ---- process data ----------------------------
ok <- TRUE

# 1. Extract metadata
log_line("Extracting metadata...")
metadata <- tryCatch({
  get_metadata(kobo_output = kobo_clean)
}, error = function(e) {
  log_line("ERROR in get_metadata: ", conditionMessage(e))
  ok <<- FALSE
  NULL
})

# 2. Extract Ne indicator data
log_line("Extracting Ne indicator data...")
indNe_data <- tryCatch({
  get_indicatorNe_data(kobo_output = kobo_clean)
}, error = function(e) {
  log_line("ERROR in get_indicatorNe_data: ", conditionMessage(e))
  ok <<- FALSE
  NULL
})

# 3. Transform Nc to Ne
if (!is.null(indNe_data)) {
  log_line("Transforming Nc to Ne with ratio: ", ratio)
  indNe_data <- tryCatch({
    transform_to_Ne(indNe_data = indNe_data, ratio = ratio)
  }, error = function(e) {
    log_line("ERROR in transform_to_Ne: ", conditionMessage(e))
    ok <<- FALSE
    NULL
  })
}

# 4. Extract PM indicator data
log_line("Extracting PM indicator data...")
indPM_data <- tryCatch({
  get_indicatorPM_data(kobo_output = kobo_clean)
}, error = function(e) {
  log_line("ERROR in get_indicatorPM_data: ", conditionMessage(e))
  ok <<- FALSE
  NULL
})

# 5. Extract DNA-based indicator data
log_line("Extracting DNA-based indicator data...")
indDNAbased_data <- tryCatch({
  get_indicatorDNAbased_data(kobo_output = kobo_clean)
}, error = function(e) {
  log_line("ERROR in get_indicatorDNAbased_data: ", conditionMessage(e))
  ok <<- FALSE
  NULL
})

# ---- save outputs ----------------------------
log_line("Saving output files...")

indNe_path      <- file.path(output_dir, "indNe_data.csv")
indPM_path      <- file.path(output_dir, "indPM_data.csv")
indDNAbased_path <- file.path(output_dir, "indDNAbased_data.csv")
metadata_path   <- file.path(output_dir, "metadata.csv")

if (!is.null(indNe_data)) {
  write.csv(indNe_data, indNe_path, row.names = FALSE, fileEncoding = "UTF-8")
  log_line("Saved: ", indNe_path, " (", nrow(indNe_data), " rows)")
}

if (!is.null(indPM_data)) {
  write.csv(indPM_data, indPM_path, row.names = FALSE, fileEncoding = "UTF-8")
  log_line("Saved: ", indPM_path, " (", nrow(indPM_data), " rows)")
}

if (!is.null(indDNAbased_data)) {
  write.csv(indDNAbased_data, indDNAbased_path, row.names = FALSE, fileEncoding = "UTF-8")
  log_line("Saved: ", indDNAbased_path, " (", nrow(indDNAbased_data), " rows)")
}

if (!is.null(metadata)) {
  write.csv(metadata, metadata_path, row.names = FALSE, fileEncoding = "UTF-8")
  log_line("Saved: ", metadata_path, " (", nrow(metadata), " rows)")
}

# ---- summary ---------------------------------
log_line("indNe_data exists: ", file.exists(indNe_path))
log_line("indPM_data exists: ", file.exists(indPM_path))
log_line("indDNAbased_data exists: ", file.exists(indDNAbased_path))
log_line("metadata exists: ", file.exists(metadata_path))
log_line("Log file: ", log_path)
log_line("=== Step2 wrapper end ===")

if (!ok) quit(status = 1)
if (!file.exists(indNe_path)) quit(status = 1)

quit(status = 0)
