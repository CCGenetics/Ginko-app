# app/modules/mod_step4.R

library(shiny)

source("modules/mod_step_frame.R")
step4_md <- file.path("content", "steps", "step4.md")

mod_step4_ui <- function(id) {
  ns <- NS(id)

  step_frame_ui(
    id = id,
    title = "04 - Country report",

    description_ui = tagList(
      tags$p(
        "Generates a country-level report summarizing genetic diversity indicators."
      ),
      includeMarkdown(step4_md)
    ),

    params_ui = tagList(
      tags$h5("Input data source"),
      radioButtons(
        inputId = ns("input_source"),
        label = NULL,
        choices = c(
          "Use output from Step 3" = "previous",
          "Upload my own files" = "upload"
        ),
        selected = "previous"
      ),

      conditionalPanel(
        condition = sprintf("input['%s'] == 'upload'", ns("input_source")),
        fileInput(
          inputId = ns("upload_indicators_full"),
          label = "Upload indicators_full.csv",
          accept = ".csv"
        ),
        fileInput(
          inputId = ns("upload_indNe"),
          label = "Upload indNe_data.csv",
          accept = ".csv"
        ),
        tags$small(
          class = "text-muted",
          "Upload both CSV files from Step 3 output (or equivalent)."
        )
      ),

      tags$hr(),

      textInput(
        inputId = ns("country_name"),
        label = "Country name",
        value = "",
        placeholder = "e.g., mexico, south_africa, france"
      ),
      tags$small(
        class = "text-muted",
        "Enter the country name exactly as it appears in your data (lowercase, use underscores instead of spaces). ",
        "Leave empty to use the first country found in the data."
      )
    ),

    process_ui = actionButton(
      inputId = ns("process"),
      label = "Generate Report"
    ),

    result_ui = tagList(
      tags$h5("Run status"),
      verbatimTextOutput(ns("run_status")),

      tags$h5("Available countries"),
      verbatimTextOutput(ns("available_countries")),

      tags$h5("Output files"),
      downloadButton(ns("download_report"), "Download country_report.html"),
      downloadButton(ns("download_log"), "Download step log")
    )
  )
}

mod_step4_server <- function(id, paths) {
  moduleServer(id, function(input, output, session) {

    report_path <- reactiveVal(NULL)
    log_path    <- reactiveVal(NULL)

    run_status <- reactiveVal("Not run yet.")
    run_id     <- reactiveVal(0)

    # Store uploaded file paths
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
          return("Run Step 3 first to see available countries.")
        } else {
          return("Upload indicators_full.csv to see available countries.")
        }
      }

      tryCatch({
        data <- read.csv(indicators_file, header = TRUE, stringsAsFactors = FALSE)
        if ("country_assessment" %in% names(data)) {
          countries <- unique(data$country_assessment)
          countries <- countries[!is.na(countries) & countries != ""]
          if (length(countries) == 0) {
            return("No countries found in data.")
          }
          paste("Found countries:", paste(countries, collapse = ", "))
        } else {
          "Column 'country_assessment' not found in data."
        }
      }, error = function(e) {
        paste("Error reading data:", conditionMessage(e))
      })
    })

    observeEvent(input$process, {

      # Create a temporary input directory for this step
      step_input_dir <- file.path(paths$base_dir, "step4_input")
      dir.create(step_input_dir, recursive = TRUE, showWarnings = FALSE)

      if (input$input_source == "previous") {
        # Use output from step3
        step3_dir <- file.path(paths$base_dir, "step3")

        required_files <- c("indicators_full.csv", "indNe_data.csv")
        missing <- required_files[!file.exists(file.path(step3_dir, required_files))]

        if (length(missing) > 0) {
          showNotification(
            paste("Step 4: missing input files from Step 3:", paste(missing, collapse = ", "),
                  ". Run Step 3 first or upload your own files."),
            type = "error"
          )
          return()
        }

        # Copy files to input dir
        for (f in required_files) {
          file.copy(file.path(step3_dir, f), file.path(step_input_dir, f), overwrite = TRUE)
        }

      } else {
        # Use uploaded files
        if (is.null(uploaded_indicators_full()) || is.null(uploaded_indNe())) {
          showNotification("Step 4: please upload both required CSV files.", type = "error")
          return()
        }

        # Copy uploaded files to input dir with correct names
        file.copy(uploaded_indicators_full(), file.path(step_input_dir, "indicators_full.csv"), overwrite = TRUE)
        file.copy(uploaded_indNe(), file.path(step_input_dir, "indNe_data.csv"), overwrite = TRUE)
      }

      # Get country name
      country_name <- trimws(input$country_name)
      if (country_name == "") {
        # Try to get first country from data
        tryCatch({
          data <- read.csv(file.path(step_input_dir, "indicators_full.csv"), header = TRUE, stringsAsFactors = FALSE)
          if ("country_assessment" %in% names(data)) {
            countries <- unique(data$country_assessment)
            countries <- countries[!is.na(countries) & countries != ""]
            if (length(countries) > 0) {
              country_name <- countries[1]
              showNotification(
                paste("No country specified, using first found:", country_name),
                type = "warning"
              )
            }
          }
        }, error = function(e) {
          # ignore
        })
      }

      if (country_name == "") {
        showNotification("Step 4: please specify a country name", type = "error")
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
        showNotification("Step 4: report generation failed (check logs)", type = "error")
      } else {
        showNotification("Step 4 finished - report generated!", type = "message")
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
