# app/modules/mod_step3.R
#
# Step 3: Estimate indicators
# Calculates genetic diversity indicators (Ne 500, PM, DNA-based).

library(shiny)

source("content/ui_strings.R")
source("modules/mod_step_frame.R")

step3_md <- file.path("content", "steps", "step3.md")

mod_step3_ui <- function(id) {
  ns <- NS(id)

  step_frame_ui(
    id = id,
    title = STEP3_TITLE,

    description_ui = tagList(
      includeMarkdown(step3_md)
    ),

    params_ui = tagList(
      tags$h5(LABEL_INPUT_SOURCE),
      radioButtons(
        inputId = ns("input_source"),
        label = NULL,
        choiceNames = list(STEP3_INPUT_FROM_STEP2, INPUT_SOURCE_UPLOAD_MULTI),
        choiceValues = list("previous", "upload"),
        selected = "previous"
      ),

      conditionalPanel(
        condition = sprintf("input['%s'] == 'upload'", ns("input_source")),
        fileInput(inputId = ns("upload_indNe"), label = STEP3_UPLOAD_INDNE, accept = ".csv"),
        fileInput(inputId = ns("upload_indPM"), label = STEP3_UPLOAD_INDPM, accept = ".csv"),
        fileInput(inputId = ns("upload_indDNAbased"), label = STEP3_UPLOAD_INDDNA, accept = ".csv"),
        fileInput(inputId = ns("upload_metadata"), label = STEP3_UPLOAD_METADATA, accept = ".csv"),
        tags$small(class = "text-muted", STEP3_UPLOAD_HELP)
      ),

      tags$hr(),

      tags$p(STEP3_PARAM_INFO),
      tags$small(class = "text-muted", STEP3_PARAM_HELP)
    ),

    process_ui = actionButton(
      inputId = ns("process"),
      label = BTN_PROCESS
    ),

    result_ui = tagList(
      tags$h5(LABEL_RUN_STATUS),
      verbatimTextOutput(ns("run_status")),

      tags$h5(LABEL_OUTPUT_FILES),
      downloadButton(ns("download_indicators_full"), STEP3_BTN_FULL),
      downloadButton(ns("download_indicatorNe"), STEP3_BTN_NE),
      downloadButton(ns("download_indicatorPM"), STEP3_BTN_PM),
      downloadButton(ns("download_indicatorDNAbased"), STEP3_BTN_DNA),
      downloadButton(ns("download_log"), BTN_DOWNLOAD_LOG)
    )
  )
}

mod_step3_server <- function(id, paths) {
  moduleServer(id, function(input, output, session) {

    indicators_full_path   <- reactiveVal(NULL)
    indicatorNe_path       <- reactiveVal(NULL)
    indicatorPM_path       <- reactiveVal(NULL)
    indicatorDNAbased_path <- reactiveVal(NULL)
    log_path               <- reactiveVal(NULL)

    run_status <- reactiveVal(STATUS_NOT_RUN)
    run_id     <- reactiveVal(0)

    uploaded_indNe       <- reactiveVal(NULL)
    uploaded_indPM       <- reactiveVal(NULL)
    uploaded_indDNAbased <- reactiveVal(NULL)
    uploaded_metadata    <- reactiveVal(NULL)

    observeEvent(input$upload_indNe, {
      req(input$upload_indNe)
      uploaded_indNe(input$upload_indNe$datapath)
    })

    observeEvent(input$upload_indPM, {
      req(input$upload_indPM)
      uploaded_indPM(input$upload_indPM$datapath)
    })

    observeEvent(input$upload_indDNAbased, {
      req(input$upload_indDNAbased)
      uploaded_indDNAbased(input$upload_indDNAbased$datapath)
    })

    observeEvent(input$upload_metadata, {
      req(input$upload_metadata)
      uploaded_metadata(input$upload_metadata$datapath)
    })

    observeEvent(input$process, {
      # Create a temporary input directory for this step
      step_input_dir <- file.path(paths$base_dir, "step3_input")
      dir.create(step_input_dir, recursive = TRUE, showWarnings = FALSE)

      if (input$input_source == "previous") {
        step2_dir <- file.path(paths$base_dir, "step2")
        required_files <- c("indNe_data.csv", "indPM_data.csv", "indDNAbased_data.csv", "metadata.csv")
        missing <- required_files[!file.exists(file.path(step2_dir, required_files))]

        if (length(missing) > 0) {
          showNotification(
            paste(STEP3_MSG_MISSING_FILES, paste(missing, collapse = ", ")),
            type = "error"
          )
          return()
        }

        for (f in required_files) {
          file.copy(file.path(step2_dir, f), file.path(step_input_dir, f), overwrite = TRUE)
        }

      } else {
        if (is.null(uploaded_indNe()) || is.null(uploaded_indPM()) ||
            is.null(uploaded_indDNAbased()) || is.null(uploaded_metadata())) {
          showNotification(STEP3_MSG_UPLOAD_ALL, type = "error")
          return()
        }

        file.copy(uploaded_indNe(), file.path(step_input_dir, "indNe_data.csv"), overwrite = TRUE)
        file.copy(uploaded_indPM(), file.path(step_input_dir, "indPM_data.csv"), overwrite = TRUE)
        file.copy(uploaded_indDNAbased(), file.path(step_input_dir, "indDNAbased_data.csv"), overwrite = TRUE)
        file.copy(uploaded_metadata(), file.path(step_input_dir, "metadata.csv"), overwrite = TRUE)
      }

      step_out_dir <- file.path(paths$base_dir, "step3")
      dir.create(step_out_dir, recursive = TRUE, showWarnings = FALSE)

      cmd <- "Rscript"
      args <- c(
        "scripts/wrappers/step3_estimate.R",
        step_input_dir,
        step_out_dir
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
      indicators_full   <- file.path(step_out_dir, "indicators_full.csv")
      indicatorNe       <- file.path(step_out_dir, "indicatorNe.csv")
      indicatorPM       <- file.path(step_out_dir, "indicatorPM.csv")
      indicatorDNAbased <- file.path(step_out_dir, "indicatorDNAbased.csv")
      logf              <- file.path(step_out_dir, "step3_wrapper.log")

      indicators_full_path(indicators_full)
      indicatorNe_path(indicatorNe)
      indicatorPM_path(indicatorPM)
      indicatorDNAbased_path(indicatorDNAbased)
      log_path(logf)
      run_id(run_id() + 1)

      # Persist system2 output
      sys_log <- file.path(step_out_dir, "step3_system2.log")
      writeLines(res, con = sys_log)

      status_msg <- paste0(
        "Exit status: ", status, "\n",
        "Input source: ", input$input_source, "\n",
        "system2 log: ", sys_log, "\n",
        "wrapper log: ", logf, "\n",
        "indicators_full exists: ", file.exists(indicators_full), "\n",
        "indicatorNe exists: ", file.exists(indicatorNe), "\n",
        "indicatorPM exists: ", file.exists(indicatorPM), "\n",
        "indicatorDNAbased exists: ", file.exists(indicatorDNAbased), "\n"
      )
      run_status(status_msg)

      if (status != 0 || !file.exists(indicators_full)) {
        showNotification(STEP3_MSG_FAILED, type = "error")
      } else {
        showNotification(STEP3_MSG_SUCCESS, type = "message")
      }
    })

    output$run_status <- renderText({
      run_id()
      run_status()
    })

    output$download_indicators_full <- downloadHandler(
      filename = function() "indicators_full.csv",
      content = function(file) {
        req(indicators_full_path())
        if (!file.exists(indicators_full_path())) stop("Missing indicators_full.csv")
        file.copy(indicators_full_path(), file)
      }
    )

    output$download_indicatorNe <- downloadHandler(
      filename = function() "indicatorNe.csv",
      content = function(file) {
        req(indicatorNe_path())
        if (!file.exists(indicatorNe_path())) stop("Missing indicatorNe.csv")
        file.copy(indicatorNe_path(), file)
      }
    )

    output$download_indicatorPM <- downloadHandler(
      filename = function() "indicatorPM.csv",
      content = function(file) {
        req(indicatorPM_path())
        if (!file.exists(indicatorPM_path())) stop("Missing indicatorPM.csv")
        file.copy(indicatorPM_path(), file)
      }
    )

    output$download_indicatorDNAbased <- downloadHandler(
      filename = function() "indicatorDNAbased.csv",
      content = function(file) {
        req(indicatorDNAbased_path())
        if (!file.exists(indicatorDNAbased_path())) stop("Missing indicatorDNAbased.csv")
        file.copy(indicatorDNAbased_path(), file)
      }
    )

    output$download_log <- downloadHandler(
      filename = function() "step3_wrapper.log",
      content = function(file) {
        req(log_path())
        if (!file.exists(log_path())) stop("Missing wrapper log")
        file.copy(log_path(), file)
      }
    )
  })
}
