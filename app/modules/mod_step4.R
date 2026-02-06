# app/modules/mod_step4.R
#
# Step 4: Country report
# Generates a country-level report summarizing genetic diversity indicators.

library(shiny)

source("content/ui_strings.R")
source("modules/mod_step_frame.R")

step4_md <- file.path("content", "steps", "step4.md")

mod_step4_ui <- function(id) {
  ns <- NS(id)

  step_frame_ui(
    id = id,
    title = STEP4_TITLE,

    description_ui = tagList(
      includeMarkdown(step4_md)
    ),

    params_ui = tagList(
      tags$h5(LABEL_INPUT_SOURCE),
      radioButtons(
        inputId = ns("input_source"),
        label = NULL,
        choiceNames = list(STEP4_INPUT_FROM_STEP3, INPUT_SOURCE_UPLOAD_MULTI),
        choiceValues = list("previous", "upload"),
        selected = "previous"
      ),

      conditionalPanel(
        condition = sprintf("input['%s'] == 'upload'", ns("input_source")),
        fileInput(inputId = ns("upload_indicators_full"), label = STEP4_UPLOAD_FULL, accept = ".csv"),
        fileInput(inputId = ns("upload_indNe"), label = STEP4_UPLOAD_INDNE, accept = ".csv"),
        tags$small(class = "text-muted", STEP4_UPLOAD_HELP)
      ),

      tags$hr(),

      textInput(
        inputId = ns("country_name"),
        label = STEP4_PARAM_COUNTRY_LABEL,
        value = "",
        placeholder = STEP4_PARAM_COUNTRY_PLACEHOLDER
      ),
      tags$small(class = "text-muted", STEP4_PARAM_COUNTRY_HELP)
    ),

    process_ui = actionButton(
      inputId = ns("process"),
      label = BTN_GENERATE_REPORT
    ),

    result_ui = tagList(
      tags$h5(LABEL_RUN_STATUS),
      verbatimTextOutput(ns("run_status")),

      tags$h5(STEP4_RESULT_COUNTRIES),
      verbatimTextOutput(ns("available_countries")),

      tags$h5(LABEL_OUTPUT_FILES),
      downloadButton(ns("download_report"), STEP4_BTN_REPORT),
      downloadButton(ns("download_log"), BTN_DOWNLOAD_LOG)
    )
  )
}

mod_step4_server <- function(id, paths) {
  moduleServer(id, function(input, output, session) {

    report_path <- reactiveVal(NULL)
    log_path    <- reactiveVal(NULL)

    run_status <- reactiveVal(STATUS_NOT_RUN)
    run_id     <- reactiveVal(0)

    uploaded_indicators_full <- reactiveVal(NULL)
    uploaded_indNe           <- reactiveVal(NULL)

    observeEvent(input$upload_indicators_full, {
      req(input$upload_indicators_full)
      uploaded_indicators_full(input$upload_indicators_full$datapath)
    })

    observeEvent(input$upload_indNe, {
      req(input$upload_indNe)
      uploaded_indNe(input$upload_indNe$datapath)
    })

    # Helper to get indicators file path based on input source
    get_indicators_file <- reactive({
      if (input$input_source == "previous") {
        step3_dir <- file.path(paths$base_dir, "step3")
        file.path(step3_dir, "indicators_full.csv")
      } else {
        uploaded_indicators_full()
      }
    })

    # Show available countries from data
    output$available_countries <- renderText({
      indicators_file <- get_indicators_file()

      if (is.null(indicators_file) || !file.exists(indicators_file)) {
        if (input$input_source == "previous") {
          return(STEP4_MSG_RUN_STEP3)
        } else {
          return(STEP4_MSG_UPLOAD_TO_SEE)
        }
      }

      tryCatch({
        data <- read.csv(indicators_file, header = TRUE, stringsAsFactors = FALSE)
        if ("country_assessment" %in% names(data)) {
          countries <- unique(data$country_assessment)
          countries <- countries[!is.na(countries) & countries != ""]
          if (length(countries) == 0) {
            return(STEP4_MSG_NO_COUNTRIES)
          }
          paste(STEP4_MSG_COUNTRIES_FOUND, paste(countries, collapse = ", "))
        } else {
          STEP4_MSG_NO_COLUMN
        }
      }, error = function(e) {
        paste(STEP4_MSG_READ_ERROR, conditionMessage(e))
      })
    })

    observeEvent(input$process, {
      # Create a temporary input directory for this step
      step_input_dir <- file.path(paths$base_dir, "step4_input")
      dir.create(step_input_dir, recursive = TRUE, showWarnings = FALSE)

      if (input$input_source == "previous") {
        step3_dir <- file.path(paths$base_dir, "step3")
        required_files <- c("indicators_full.csv", "indNe_data.csv")
        missing <- required_files[!file.exists(file.path(step3_dir, required_files))]

        if (length(missing) > 0) {
          showNotification(
            paste(STEP4_MSG_MISSING_FILES, paste(missing, collapse = ", ")),
            type = "error"
          )
          return()
        }

        for (f in required_files) {
          file.copy(file.path(step3_dir, f), file.path(step_input_dir, f), overwrite = TRUE)
        }

      } else {
        if (is.null(uploaded_indicators_full()) || is.null(uploaded_indNe())) {
          showNotification(STEP4_MSG_UPLOAD_BOTH, type = "error")
          return()
        }

        file.copy(uploaded_indicators_full(), file.path(step_input_dir, "indicators_full.csv"), overwrite = TRUE)
        file.copy(uploaded_indNe(), file.path(step_input_dir, "indNe_data.csv"), overwrite = TRUE)
      }

      # Get country name
      country_name <- trimws(input$country_name)
      if (country_name == "") {
        tryCatch({
          data <- read.csv(file.path(step_input_dir, "indicators_full.csv"), header = TRUE, stringsAsFactors = FALSE)
          if ("country_assessment" %in% names(data)) {
            countries <- unique(data$country_assessment)
            countries <- countries[!is.na(countries) & countries != ""]
            if (length(countries) > 0) {
              country_name <- countries[1]
              showNotification(
                paste(STEP4_MSG_AUTO_COUNTRY, country_name),
                type = "warning"
              )
            }
          }
        }, error = function(e) {
          # ignore
        })
      }

      if (country_name == "") {
        showNotification(STEP4_MSG_SPECIFY_COUNTRY, type = "error")
        return()
      }

      step_out_dir <- file.path(paths$base_dir, "step4")
      dir.create(step_out_dir, recursive = TRUE, showWarnings = FALSE)

      cmd <- "Rscript"
      args <- c(
        "scripts/wrappers/step4_report.R",
        step_input_dir,
        step_out_dir,
        country_name
      )

      run_status(paste0(
        "Running:\n", cmd, " ", paste(args, collapse = " "), "\n",
        "Input source: ", input$input_source, "\n",
        "Country: ", country_name, "\n"
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
      report <- file.path(step_out_dir, "country_report.html")
      logf   <- file.path(step_out_dir, "step4_wrapper.log")

      report_path(report)
      log_path(logf)
      run_id(run_id() + 1)

      # Persist system2 output
      sys_log <- file.path(step_out_dir, "step4_system2.log")
      writeLines(res, con = sys_log)

      status_msg <- paste0(
        "Exit status: ", status, "\n",
        "Input source: ", input$input_source, "\n",
        "Country: ", country_name, "\n",
        "system2 log: ", sys_log, "\n",
        "wrapper log: ", logf, "\n",
        "report exists: ", file.exists(report), "\n"
      )
      run_status(status_msg)

      if (status != 0 || !file.exists(report)) {
        showNotification(STEP4_MSG_FAILED, type = "error")
      } else {
        showNotification(STEP4_MSG_SUCCESS, type = "message")
      }
    })

    output$run_status <- renderText({
      run_id()
      run_status()
    })

    output$download_report <- downloadHandler(
      filename = function() "country_report.html",
      content = function(file) {
        req(report_path())
        if (!file.exists(report_path())) stop("Missing country_report.html")
        file.copy(report_path(), file)
      }
    )

    output$download_log <- downloadHandler(
      filename = function() "step4_wrapper.log",
      content = function(file) {
        req(log_path())
        if (!file.exists(log_path())) stop("Missing wrapper log")
        file.copy(log_path(), file)
      }
    )
  })
}
