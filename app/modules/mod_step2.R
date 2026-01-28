# app/modules/mod_step2.R
#
# Step 2: Clean & extract indicators data
# Transforms cleaned Kobo data into indicator-specific datasets.

library(shiny)

source("content/ui_strings.R")
source("modules/mod_step_frame.R")

step2_md <- file.path("content", "steps", "step2.md")

mod_step2_ui <- function(id) {
  ns <- NS(id)

  step_frame_ui(
    id = id,
    title = STEP2_TITLE,

    description_ui = tagList(
      includeMarkdown(step2_md)
    ),

    params_ui = tagList(
      tags$h5(LABEL_INPUT_SOURCE),
      radioButtons(
        inputId = ns("input_source"),
        label = NULL,
        choiceNames = list(STEP2_INPUT_FROM_STEP1, INPUT_SOURCE_UPLOAD),
        choiceValues = list("previous", "upload"),
        selected = "previous"
      ),

      conditionalPanel(
        condition = sprintf("input['%s'] == 'upload'", ns("input_source")),
        fileInput(
          inputId = ns("upload_clean"),
          label = STEP2_UPLOAD_LABEL,
          accept = ".csv"
        ),
        tags$small(class = "text-muted", STEP2_UPLOAD_HELP)
      ),

      tags$hr(),

      numericInput(
        inputId = ns("ratio"),
        label = STEP2_PARAM_RATIO_LABEL,
        value = 0.1,
        min = 0,
        max = 1,
        step = 0.01
      ),
      tags$small(class = "text-muted", STEP2_PARAM_RATIO_HELP)
    ),

    process_ui = actionButton(
      inputId = ns("process"),
      label = BTN_PROCESS
    ),

    result_ui = tagList(
      tags$h5(LABEL_RUN_STATUS),
      verbatimTextOutput(ns("run_status")),

      tags$h5(LABEL_OUTPUT_FILES),
      downloadButton(ns("download_indNe"), STEP2_BTN_INDNE),
      downloadButton(ns("download_indPM"), STEP2_BTN_INDPM),
      downloadButton(ns("download_indDNAbased"), STEP2_BTN_INDDNA),
      downloadButton(ns("download_metadata"), STEP2_BTN_METADATA),
      downloadButton(ns("download_log"), BTN_DOWNLOAD_LOG)
    )
  )
}

mod_step2_server <- function(id, paths) {
  moduleServer(id, function(input, output, session) {

    indNe_path       <- reactiveVal(NULL)
    indPM_path       <- reactiveVal(NULL)
    indDNAbased_path <- reactiveVal(NULL)
    metadata_path    <- reactiveVal(NULL)
    log_path         <- reactiveVal(NULL)

    run_status <- reactiveVal(STATUS_NOT_RUN)
    run_id     <- reactiveVal(0)

    uploaded_file <- reactiveVal(NULL)

    observeEvent(input$upload_clean, {
      req(input$upload_clean)
      uploaded_file(input$upload_clean$datapath)
    })

    observeEvent(input$process, {
      # Determine input file based on source selection
      if (input$input_source == "previous") {
        step1_dir <- file.path(paths$base_dir, "step1")
        input_csv <- file.path(step1_dir, "kobo_output_clean.csv")

        if (!file.exists(input_csv)) {
          showNotification(STEP2_MSG_MISSING_FILE, type = "error")
          return()
        }
      } else {
        if (is.null(uploaded_file())) {
          showNotification(STEP2_MSG_UPLOAD_FIRST, type = "error")
          return()
        }
        input_csv <- uploaded_file()
      }

      # Validate ratio
      ratio <- input$ratio
      if (is.na(ratio) || ratio < 0 || ratio > 1) {
        showNotification(STEP2_MSG_INVALID_RATIO, type = "error")
        return()
      }

      step_out_dir <- file.path(paths$base_dir, "step2")
      dir.create(step_out_dir, recursive = TRUE, showWarnings = FALSE)

      cmd <- "Rscript"
      args <- c(
        "scripts/wrappers/step2_clean_extract.R",
        input_csv,
        step_out_dir,
        as.character(ratio)
      )

      run_status(paste0(
        "Running:\n", cmd, " ", paste(args, collapse = " "), "\n",
        "Input source: ", input$input_source, "\n"
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
      indNe       <- file.path(step_out_dir, "indNe_data.csv")
      indPM       <- file.path(step_out_dir, "indPM_data.csv")
      indDNAbased <- file.path(step_out_dir, "indDNAbased_data.csv")
      metadata    <- file.path(step_out_dir, "metadata.csv")
      logf        <- file.path(step_out_dir, "step2_wrapper.log")

      indNe_path(indNe)
      indPM_path(indPM)
      indDNAbased_path(indDNAbased)
      metadata_path(metadata)
      log_path(logf)
      run_id(run_id() + 1)

      # Persist system2 output
      sys_log <- file.path(step_out_dir, "step2_system2.log")
      writeLines(res, con = sys_log)

      status_msg <- paste0(
        "Exit status: ", status, "\n",
        "Input source: ", input$input_source, "\n",
        "system2 log: ", sys_log, "\n",
        "wrapper log: ", logf, "\n",
        "indNe_data exists: ", file.exists(indNe), "\n",
        "indPM_data exists: ", file.exists(indPM), "\n",
        "indDNAbased_data exists: ", file.exists(indDNAbased), "\n",
        "metadata exists: ", file.exists(metadata), "\n"
      )
      run_status(status_msg)

      if (status != 0 || !file.exists(indNe)) {
        showNotification(STEP2_MSG_FAILED, type = "error")
      } else {
        showNotification(STEP2_MSG_SUCCESS, type = "message")
      }
    })

    output$run_status <- renderText({
      run_id()
      run_status()
    })

    output$download_indNe <- downloadHandler(
      filename = function() "indNe_data.csv",
      content = function(file) {
        req(indNe_path())
        if (!file.exists(indNe_path())) stop("Missing indNe_data.csv")
        file.copy(indNe_path(), file)
      }
    )

    output$download_indPM <- downloadHandler(
      filename = function() "indPM_data.csv",
      content = function(file) {
        req(indPM_path())
        if (!file.exists(indPM_path())) stop("Missing indPM_data.csv")
        file.copy(indPM_path(), file)
      }
    )

    output$download_indDNAbased <- downloadHandler(
      filename = function() "indDNAbased_data.csv",
      content = function(file) {
        req(indDNAbased_path())
        if (!file.exists(indDNAbased_path())) stop("Missing indDNAbased_data.csv")
        file.copy(indDNAbased_path(), file)
      }
    )

    output$download_metadata <- downloadHandler(
      filename = function() "metadata.csv",
      content = function(file) {
        req(metadata_path())
        if (!file.exists(metadata_path())) stop("Missing metadata.csv")
        file.copy(metadata_path(), file)
      }
    )

    output$download_log <- downloadHandler(
      filename = function() "step2_wrapper.log",
      content = function(file) {
        req(log_path())
        if (!file.exists(log_path())) stop("Missing wrapper log")
        file.copy(log_path(), file)
      }
    )
  })
}
