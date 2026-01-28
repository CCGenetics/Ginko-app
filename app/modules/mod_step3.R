# app/modules/mod_step3.R

library(shiny)

source("modules/mod_step_frame.R")
step3_md <- file.path("content", "steps", "step3.md")

mod_step3_ui <- function(id) {
  ns <- NS(id)

  step_frame_ui(
    id = id,
    title = "03 - Estimate indicators",

    description_ui = tagList(
      tags$p(
        "Calculates genetic diversity indicators required by the ",
        "Global Biodiversity Framework (Ne 500, PM, DNA-based)."
      ),
      includeMarkdown(step3_md)
    ),

    params_ui = tagList(
      tags$h5("Input data source"),
      radioButtons(
        inputId = ns("input_source"),
        label = NULL,
        choices = c(
          "Use output from Step 2" = "previous",
          "Upload my own files" = "upload"
        ),
        selected = "previous"
      ),

      conditionalPanel(
        condition = sprintf("input['%s'] == 'upload'", ns("input_source")),
        fileInput(
          inputId = ns("upload_indNe"),
          label = "Upload indNe_data.csv",
          accept = ".csv"
        ),
        fileInput(
          inputId = ns("upload_indPM"),
          label = "Upload indPM_data.csv",
          accept = ".csv"
        ),
        fileInput(
          inputId = ns("upload_indDNAbased"),
          label = "Upload indDNAbased_data.csv",
          accept = ".csv"
        ),
        fileInput(
          inputId = ns("upload_metadata"),
          label = "Upload metadata.csv",
          accept = ".csv"
        ),
        tags$small(
          class = "text-muted",
          "Upload all 4 CSV files from Step 2 output (or equivalent)."
        )
      ),

      tags$hr(),

      tags$p("This step uses the default Ne threshold of 500."),
      tags$small(
        class = "text-muted",
        "The Ne 500 indicator calculates the proportion of populations within species ",
        "with an effective population size greater than 500."
      )
    ),

    process_ui = actionButton(
      inputId = ns("process"),
      label = "Process"
    ),

    result_ui = tagList(
      tags$h5("Run status"),
      verbatimTextOutput(ns("run_status")),

      tags$h5("Output files"),
      downloadButton(ns("download_indicators_full"), "Download indicators_full.csv"),
      downloadButton(ns("download_indicatorNe"), "Download indicatorNe.csv"),
      downloadButton(ns("download_indicatorPM"), "Download indicatorPM.csv"),
      downloadButton(ns("download_indicatorDNAbased"), "Download indicatorDNAbased.csv"),
      downloadButton(ns("download_log"), "Download step log")
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

    run_status <- reactiveVal("Not run yet.")
    run_id     <- reactiveVal(0)

    # Store uploaded file paths
    uploaded_indNe      <- reactiveVal(NULL)
    uploaded_indPM      <- reactiveVal(NULL)
    uploaded_indDNAbased <- reactiveVal(NULL)
    uploaded_metadata   <- reactiveVal(NULL)

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
        # Use output from step2
        step2_dir <- file.path(paths$base_dir, "step2")

        required_files <- c("indNe_data.csv", "indPM_data.csv", "indDNAbased_data.csv", "metadata.csv")
        missing <- required_files[!file.exists(file.path(step2_dir, required_files))]

        if (length(missing) > 0) {
          showNotification(
            paste("Step 3: missing input files from Step 2:", paste(missing, collapse = ", "),
                  ". Run Step 2 first or upload your own files."),
            type = "error"
          )
          return()
        }

        # Copy files to input dir
        for (f in required_files) {
          file.copy(file.path(step2_dir, f), file.path(step_input_dir, f), overwrite = TRUE)
        }

      } else {
        # Use uploaded files
        if (is.null(uploaded_indNe()) || is.null(uploaded_indPM()) ||
            is.null(uploaded_indDNAbased()) || is.null(uploaded_metadata())) {
          showNotification("Step 3: please upload all 4 required CSV files.", type = "error")
          return()
        }

        # Copy uploaded files to input dir with correct names
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
        showNotification("Step 3: processing failed (check logs)", type = "error")
      } else {
        showNotification("Step 3 finished successfully", type = "message")
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
