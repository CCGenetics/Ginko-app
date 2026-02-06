# app/modules/mod_step1.R
#
# Step 1: Raw data quality check
# Validates Kobo export data and flags records for manual review.

library(shiny)

source("content/ui_strings.R")
source("modules/mod_step_frame.R")

step1_md <- file.path("content", "steps", "step1.md")

mod_step1_ui <- function(id) {
  ns <- NS(id)

  step_frame_ui(
    id = id,
    title = STEP1_TITLE,

    description_ui = tagList(
      includeMarkdown(step1_md)
    ),

    params_ui = tagList(
      checkboxInput(
        inputId = ns("keep_to_check"),
        label = STEP1_PARAM_KEEP_LABEL,
        value = FALSE
      )
    ),

    process_ui = actionButton(
      inputId = ns("process"),
      label = BTN_PROCESS
    ),

    result_ui = tagList(
      tags$h5(LABEL_RUN_STATUS),
      verbatimTextOutput(ns("run_status")),

      tags$h5(STEP1_RESULT_PREVIEW),
      uiOutput(ns("report_preview")),

      downloadButton(ns("download_tocheck"), STEP1_BTN_TOCHECK),
      downloadButton(ns("download_clean"), STEP1_BTN_CLEAN),
      downloadButton(ns("download_report"), STEP1_BTN_REPORT),
      downloadButton(ns("download_log"), BTN_DOWNLOAD_LOG)
    )
  )
}

mod_step1_server <- function(id, paths) {
  moduleServer(id, function(input, output, session) {

    tocheck_path <- reactiveVal(NULL)
    clean_path   <- reactiveVal(NULL)
    report_path  <- reactiveVal(NULL)
    log_path     <- reactiveVal(NULL)

    run_status   <- reactiveVal(STATUS_NOT_RUN)
    run_id       <- reactiveVal(0)

    observeEvent(input$process, {
      input_csv <- file.path(paths$input_dir, "00_raw_data.csv")

      if (!file.exists(input_csv)) {
        showNotification(STEP1_MSG_MISSING_FILE, type = "error")
        return()
      }

      step_out_dir <- file.path(paths$base_dir, "step1")
      dir.create(step_out_dir, recursive = TRUE, showWarnings = FALSE)

      cmd <- "Rscript"
      args <- c(
        "scripts/wrappers/step1_quality_check.R",
        input_csv,
        step_out_dir,
        as.character(input$keep_to_check)
      )

      run_status(paste0(
        "Running:\n", cmd, " ", paste(args, collapse = " "), "\n"
      ))

      res <- system2(
        command = cmd,
        args = args,
        stdout = TRUE,
        stderr = TRUE
      )
      status <- attr(res, "status")
      if (is.null(status)) status <- 0

      # Expected outputs
      tocheck <- file.path(step_out_dir, "kobo_output_tocheck.csv")
      clean   <- file.path(step_out_dir, "kobo_output_clean.csv")
      report  <- file.path(step_out_dir, "step1_quality_check_report.html")
      logf    <- file.path(step_out_dir, "step1_wrapper.log")

      tocheck_path(tocheck)
      clean_path(clean)
      report_path(report)
      log_path(logf)
      run_id(run_id() + 1)

      # Persist system2 output
      sys_log <- file.path(step_out_dir, "step1_system2.log")
      writeLines(res, con = sys_log)

      status_msg <- paste0(
        "Exit status: ", status, "\n",
        "system2 log: ", sys_log, "\n",
        "wrapper log: ", logf, "\n",
        "report exists: ", file.exists(report), "\n",
        "tocheck exists: ", file.exists(tocheck), "\n",
        "clean exists: ", file.exists(clean), "\n"
      )
      run_status(status_msg)

      if (status != 0 || !file.exists(report)) {
        showNotification(STEP1_MSG_FAILED, type = "error")
      } else {
        showNotification(STEP1_MSG_SUCCESS, type = "message")
      }
    })

    output$run_status <- renderText({
      run_id()
      run_status()
    })

    output$report_preview <- renderUI({
      run_id()
      req(report_path())
      if (file.exists(report_path())) {
        tags$code(report_path())
      } else {
        tags$em(STEP1_PREVIEW_NONE)
      }
    })

    output$download_tocheck <- downloadHandler(
      filename = function() "kobo_output_tocheck.csv",
      content = function(file) {
        req(tocheck_path())
        if (!file.exists(tocheck_path())) stop("Missing kobo_output_tocheck.csv")
        file.copy(tocheck_path(), file)
      }
    )

    output$download_clean <- downloadHandler(
      filename = function() "kobo_output_clean.csv",
      content = function(file) {
        req(clean_path())
        if (!file.exists(clean_path())) stop("Missing kobo_output_clean.csv")
        file.copy(clean_path(), file)
      }
    )

    output$download_report <- downloadHandler(
      filename = function() "step1_quality_check_report.html",
      content = function(file) {
        req(report_path())
        if (!file.exists(report_path())) stop("Missing report HTML")
        file.copy(report_path(), file)
      }
    )

    output$download_log <- downloadHandler(
      filename = function() "step1_wrapper.log",
      content = function(file) {
        req(log_path())
        if (!file.exists(log_path())) stop("Missing wrapper log")
        file.copy(log_path(), file)
      }
    )
  })
}
