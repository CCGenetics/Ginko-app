# =============================================================================
# UI Strings Configuration
# =============================================================================
# This file contains all user-facing text labels for the Ginko web application.
# Non-developers can edit these strings to customize the interface.
#
# IMPORTANT: Keep the variable names unchanged. Only modify the text in quotes.
# =============================================================================

# -----------------------------------------------------------------------------
# Application title
# -----------------------------------------------------------------------------
APP_TITLE <- "Ginko!"

# -----------------------------------------------------------------------------
# Common labels (used across multiple steps)
# -----------------------------------------------------------------------------
LABEL_DESCRIPTION      <- "Description"
LABEL_PARAMETERS       <- "Parameters"
LABEL_PROCESS          <- "Process"
LABEL_RESULT           <- "Result"
LABEL_RUN_STATUS       <- "Run status"
LABEL_OUTPUT_FILES     <- "Output files"
LABEL_INPUT_SOURCE     <- "Input data source"
LABEL_UPLOAD_CSV       <- "Upload CSV file"

# Input source radio button options
INPUT_SOURCE_PREVIOUS  <- "Use output from previous step"
INPUT_SOURCE_UPLOAD    <- "Upload my own file"
INPUT_SOURCE_UPLOAD_MULTI <- "Upload my own files"

# Common button labels
BTN_PROCESS            <- "Process"
BTN_GENERATE_REPORT    <- "Generate Report"
BTN_DOWNLOAD_LOG       <- "Download step log"

# Common status messages
STATUS_NOT_RUN         <- "Not run yet."
STATUS_NO_PARAMS       <- "No parameters."
STATUS_NO_RESULTS      <- "No results yet."

# -----------------------------------------------------------------------------
# About box
# -----------------------------------------------------------------------------
ABOUT_TITLE            <- "About this app"

# -----------------------------------------------------------------------------
# Step 0 - Upload data
# -----------------------------------------------------------------------------
STEP0_TITLE            <- "00 - Upload data"

# -----------------------------------------------------------------------------
# Step 1 - Quality check
# -----------------------------------------------------------------------------
STEP1_TITLE            <- "01 - Raw data quality check"
STEP1_PARAM_KEEP_LABEL <- "Keep records flagged for manual review in the CLEAN output (keep_to_check)"

STEP1_RESULT_PREVIEW   <- "Report preview"
STEP1_BTN_TOCHECK      <- "Download to-check CSV"
STEP1_BTN_CLEAN        <- "Download clean CSV"
STEP1_BTN_REPORT       <- "Download report (HTML)"

STEP1_MSG_MISSING_FILE <- "Step 1: missing uploaded file. Please upload a CSV file first."
STEP1_MSG_SUCCESS      <- "Step 1 finished"
STEP1_MSG_FAILED       <- "Step 1: report was not generated (check logs)"
STEP1_PREVIEW_NONE     <- "No report generated yet. Download logs to see why."

# -----------------------------------------------------------------------------
# Step 2 - Clean & extract indicators data
# -----------------------------------------------------------------------------
STEP2_TITLE            <- "02 - Clean & extract indicators data"
STEP2_INPUT_FROM_STEP1 <- "Use output from Step 1"
STEP2_UPLOAD_LABEL     <- "Upload kobo_output_clean.csv"
STEP2_UPLOAD_HELP      <- "Upload a CSV file with cleaned Kobo data (output from Step 1 or equivalent)."

STEP2_PARAM_RATIO_LABEL <- "Nc:Ne ratio (0.0-1.0)"
STEP2_PARAM_RATIO_HELP  <- "This ratio is used to transform Nc (census size) to Ne (effective population size). Default value of 0.1 means Ne = Nc * 0.1"

STEP2_BTN_INDNE        <- "Download indNe_data.csv"
STEP2_BTN_INDPM        <- "Download indPM_data.csv"
STEP2_BTN_INDDNA       <- "Download indDNAbased_data.csv"
STEP2_BTN_METADATA     <- "Download metadata.csv"

STEP2_MSG_MISSING_FILE <- "Step 2: missing input file from Step 1. Run Step 1 first or upload your own file."
STEP2_MSG_UPLOAD_FIRST <- "Step 2: please upload a CSV file first."
STEP2_MSG_INVALID_RATIO <- "Step 2: ratio must be between 0 and 1"
STEP2_MSG_SUCCESS      <- "Step 2 finished successfully"
STEP2_MSG_FAILED       <- "Step 2: processing failed (check logs)"

# -----------------------------------------------------------------------------
# Step 3 - Estimate indicators
# -----------------------------------------------------------------------------
STEP3_TITLE            <- "03 - Estimate indicators"
STEP3_INPUT_FROM_STEP2 <- "Use output from Step 2"
STEP3_UPLOAD_INDNE     <- "Upload indNe_data.csv"
STEP3_UPLOAD_INDPM     <- "Upload indPM_data.csv"
STEP3_UPLOAD_INDDNA    <- "Upload indDNAbased_data.csv"
STEP3_UPLOAD_METADATA  <- "Upload metadata.csv"
STEP3_UPLOAD_HELP      <- "Upload all 4 CSV files from Step 2 output (or equivalent)."

STEP3_PARAM_INFO       <- "This step uses the default Ne threshold of 500."
STEP3_PARAM_HELP       <- "The Ne 500 indicator calculates the proportion of populations within species with an effective population size greater than 500."

STEP3_BTN_FULL         <- "Download indicators_full.csv"
STEP3_BTN_NE           <- "Download indicatorNe.csv"
STEP3_BTN_PM           <- "Download indicatorPM.csv"
STEP3_BTN_DNA          <- "Download indicatorDNAbased.csv"

STEP3_MSG_MISSING_FILES <- "Step 3: missing input files from Step 2. Run Step 2 first or upload your own files."
STEP3_MSG_UPLOAD_ALL   <- "Step 3: please upload all 4 required CSV files."
STEP3_MSG_SUCCESS      <- "Step 3 finished successfully"
STEP3_MSG_FAILED       <- "Step 3: processing failed (check logs)"

# -----------------------------------------------------------------------------
# Step 4 - Country report
# -----------------------------------------------------------------------------
STEP4_TITLE            <- "04 - Country report"
STEP4_INPUT_FROM_STEP3 <- "Use output from Step 3"
STEP4_UPLOAD_FULL      <- "Upload indicators_full.csv"
STEP4_UPLOAD_INDNE     <- "Upload indNe_data.csv"
STEP4_UPLOAD_HELP      <- "Upload both CSV files from Step 3 output (or equivalent)."

STEP4_PARAM_COUNTRY_LABEL <- "Country name"
STEP4_PARAM_COUNTRY_PLACEHOLDER <- "e.g., mexico, south_africa, france"
STEP4_PARAM_COUNTRY_HELP <- "Enter the country name exactly as it appears in your data (lowercase, use underscores instead of spaces). Leave empty to use the first country found in the data."

STEP4_RESULT_COUNTRIES <- "Available countries"
STEP4_BTN_REPORT       <- "Download country_report.html"

STEP4_MSG_RUN_STEP3    <- "Run Step 3 first to see available countries."
STEP4_MSG_UPLOAD_TO_SEE <- "Upload indicators_full.csv to see available countries."
STEP4_MSG_NO_COUNTRIES <- "No countries found in data."
STEP4_MSG_COUNTRIES_FOUND <- "Found countries:"
STEP4_MSG_NO_COLUMN    <- "Column 'country_assessment' not found in data."
STEP4_MSG_READ_ERROR   <- "Error reading data:"
STEP4_MSG_MISSING_FILES <- "Step 4: missing input files from Step 3. Run Step 3 first or upload your own files."
STEP4_MSG_UPLOAD_BOTH  <- "Step 4: please upload both required CSV files."
STEP4_MSG_AUTO_COUNTRY <- "No country specified, using first found:"
STEP4_MSG_SPECIFY_COUNTRY <- "Step 4: please specify a country name"
STEP4_MSG_SUCCESS      <- "Step 4 finished - report generated!"
STEP4_MSG_FAILED       <- "Step 4: report generation failed (check logs)"
