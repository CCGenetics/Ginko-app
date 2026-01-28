# app/scripts/wrappers/step3_estimate.R
#
# Step 3 Wrapper: Estimate Indicators
# Calculates genetic diversity indicators (Ne 500, PM, DNA-based).
#
# Usage: Rscript step3_estimate.R <input_dir> <output_dir>
#
# Outputs:
#   - indicators_full.csv: All indicators joined with metadata
#   - indicatorNe.csv: Ne 500 indicator values per assessment
#   - indicatorPM.csv: PM indicator values per taxon
#   - indicatorDNAbased.csv: DNA-based indicator counts per country

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  stop("Usage: Rscript step3_estimate.R <input_dir> <output_dir>")
}

input_dir  <- args[1]
output_dir <- args[2]

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

log_path <- file.path(output_dir, "step3_wrapper.log")

log_line <- function(...) {
  msg <- paste0(..., collapse = "")
  cat(msg, "\n")
  cat(msg, "\n", file = log_path, append = TRUE)
}

log_line("=== Step3 wrapper start ===")
log_line("input_dir: ", input_dir)
log_line("output_dir: ", output_dir)

# ---- check input files exist -----------------
indNe_file      <- file.path(input_dir, "indNe_data.csv")
indPM_file      <- file.path(input_dir, "indPM_data.csv")
indDNAbased_file <- file.path(input_dir, "indDNAbased_data.csv")
metadata_file   <- file.path(input_dir, "metadata.csv")

if (!file.exists(indNe_file)) stop(paste("Missing:", indNe_file))
if (!file.exists(indPM_file)) stop(paste("Missing:", indPM_file))
if (!file.exists(indDNAbased_file)) stop(paste("Missing:", indDNAbased_file))
if (!file.exists(metadata_file)) stop(paste("Missing:", metadata_file))

# ---- best-effort locale ----------------------
try(Sys.setlocale("LC_ALL", "C.UTF-8"), silent = TRUE)
try(Sys.setlocale("LC_CTYPE", "C.UTF-8"), silent = TRUE)

# ---- ensure required packages exist ----------
required <- c("tidyr", "dplyr", "magrittr")

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
})

# ---- source Ginko-Rfun functions -------------
rfun_dir <- file.path("scripts", "Ginko-Rfun")
source(file.path(rfun_dir, "estimate_indicatorNe.R"))
log_line("Sourced estimate_indicatorNe.R")

# ---- read input data -------------------------
log_line("Reading input files...")

indNe_data <- tryCatch({
  read.csv(indNe_file, header = TRUE, stringsAsFactors = FALSE)
}, error = function(e) {
  log_line("ERROR reading indNe_data: ", conditionMessage(e))
  quit(status = 1)
})

indPM_data <- tryCatch({
  read.csv(indPM_file, header = TRUE, stringsAsFactors = FALSE)
}, error = function(e) {
  log_line("ERROR reading indPM_data: ", conditionMessage(e))
  quit(status = 1)
})

indDNAbased_data <- tryCatch({
  read.csv(indDNAbased_file, header = TRUE, stringsAsFactors = FALSE)
}, error = function(e) {
  log_line("ERROR reading indDNAbased_data: ", conditionMessage(e))
  quit(status = 1)
})

metadata <- tryCatch({
  read.csv(metadata_file, header = TRUE, stringsAsFactors = FALSE)
}, error = function(e) {
  log_line("ERROR reading metadata: ", conditionMessage(e))
  quit(status = 1)
})

log_line("indNe_data rows: ", nrow(indNe_data))
log_line("indPM_data rows: ", nrow(indPM_data))
log_line("indDNAbased_data rows: ", nrow(indDNAbased_data))
log_line("metadata rows: ", nrow(metadata))

# ---- estimate indicators ---------------------
ok <- TRUE

# 1. Ne 500 indicator
log_line("Estimating Ne 500 indicator...")
indicatorNe <- tryCatch({
  # estimate_indicatorNe needs metadata in global scope for left_join
  # We'll do it inline instead to avoid that dependency
  indNe_data %>%
    group_by(X_uuid) %>%
    summarise(
      n_pops = n(),
      n_pops_Ne_data = sum(!is.na(Ne_combined)),
      n_pops_more_500 = sum(Ne_combined > 500, na.rm = TRUE),
      indicatorNe = n_pops_more_500 / n_pops_Ne_data,
      .groups = "drop"
    )
}, error = function(e) {
  log_line("ERROR estimating indicatorNe: ", conditionMessage(e))
  ok <<- FALSE
  NULL
})

if (!is.null(indicatorNe)) {
  log_line("indicatorNe calculated for ", nrow(indicatorNe), " assessments")
}

# 2. PM indicator
log_line("Estimating PM indicator...")
indicatorPM <- tryCatch({
  indPM_data %>%
    mutate(
      indicatorPM = n_extant_populations / (n_extant_populations + n_extinct_populations)
    )
}, error = function(e) {
  log_line("ERROR estimating indicatorPM: ", conditionMessage(e))
  ok <<- FALSE
  NULL
})

if (!is.null(indicatorPM)) {
  log_line("indicatorPM calculated for ", nrow(indicatorPM), " taxa")
}

# 3. DNA-based indicator (count by country)
log_line("Estimating DNA-based indicator...")
indicatorDNAbased <- tryCatch({
  indDNAbased_data %>%
    select(country_assessment, taxon, temp_gen_monitoring) %>%
    filter(!duplicated(.)) %>%
    filter(temp_gen_monitoring == "yes") %>%
    group_by(country_assessment) %>%
    summarise(n_taxon_gen_monitoring = n(), .groups = "drop")
}, error = function(e) {
  log_line("ERROR estimating indicatorDNAbased: ", conditionMessage(e))
  ok <<- FALSE
  NULL
})

if (!is.null(indicatorDNAbased)) {
  log_line("indicatorDNAbased calculated for ", nrow(indicatorDNAbased), " countries")
}

# 4. Join indicators and metadata
log_line("Joining indicators with metadata...")
indicators_full <- tryCatch({
  result <- metadata

  if (!is.null(indicatorNe)) {
    result <- left_join(result, indicatorNe, by = "X_uuid")
  }

  if (!is.null(indicatorPM)) {
    # indicatorPM already has all PM columns, just need the indicator value
    pm_subset <- indicatorPM %>% select(X_uuid, indicatorPM)
    result <- left_join(result, pm_subset, by = "X_uuid")
  }

  # Add PM raw data columns if not present
  if (!("n_extant_populations" %in% names(result)) && !is.null(indicatorPM)) {
    pm_cols <- indicatorPM %>%
      select(X_uuid, n_extant_populations, n_extinct_populations)
    result <- left_join(result, pm_cols, by = "X_uuid")
  }

  result
}, error = function(e) {
  log_line("ERROR joining data: ", conditionMessage(e))
  ok <<- FALSE
  NULL
})

if (!is.null(indicators_full)) {
  log_line("indicators_full has ", nrow(indicators_full), " rows and ", ncol(indicators_full), " columns")
}

# ---- save outputs ----------------------------
log_line("Saving output files...")

indicators_full_path <- file.path(output_dir, "indicators_full.csv")
indicatorNe_path     <- file.path(output_dir, "indicatorNe.csv")
indicatorPM_path     <- file.path(output_dir, "indicatorPM.csv")
indicatorDNAbased_path <- file.path(output_dir, "indicatorDNAbased.csv")

if (!is.null(indicators_full)) {
  write.csv(indicators_full, indicators_full_path, row.names = FALSE, fileEncoding = "UTF-8")
  log_line("Saved: ", indicators_full_path)
}

if (!is.null(indicatorNe)) {
  write.csv(indicatorNe, indicatorNe_path, row.names = FALSE, fileEncoding = "UTF-8")
  log_line("Saved: ", indicatorNe_path)
}

if (!is.null(indicatorPM)) {
  write.csv(indicatorPM, indicatorPM_path, row.names = FALSE, fileEncoding = "UTF-8")
  log_line("Saved: ", indicatorPM_path)
}

if (!is.null(indicatorDNAbased)) {
  write.csv(indicatorDNAbased, indicatorDNAbased_path, row.names = FALSE, fileEncoding = "UTF-8")
  log_line("Saved: ", indicatorDNAbased_path)
}

# ---- copy input files to output for step4 ----
# Step 4 needs indNe_data.csv alongside indicators_full.csv
file.copy(indNe_file, file.path(output_dir, "indNe_data.csv"), overwrite = TRUE)
log_line("Copied indNe_data.csv to output_dir for step4")

# ---- summary ---------------------------------
log_line("indicators_full exists: ", file.exists(indicators_full_path))
log_line("indicatorNe exists: ", file.exists(indicatorNe_path))
log_line("indicatorPM exists: ", file.exists(indicatorPM_path))
log_line("indicatorDNAbased exists: ", file.exists(indicatorDNAbased_path))
log_line("Log file: ", log_path)
log_line("=== Step3 wrapper end ===")

if (!ok) quit(status = 1)
if (!file.exists(indicators_full_path)) quit(status = 1)

quit(status = 0)
