# app/modules/mod_step2.R

library(shiny)

source("modules/mod_step_frame.R")

mod_step2_ui <- function(id) {
  ns <- NS(id)

  step_frame_ui(
    id = id,
    title = "02 — Clean & extract indicators data",

    description_ui = tagList(
      tags$p(
        "Transforms quality-checked raw data into indicator-specific datasets ",
        "required for further analysis (Ne, PM, DNA-based)."
      )
    ),

    params_ui = tags$p("This step does not require any parameters."),

    process_ui = actionButton(
      inputId = ns("process"),
      label = "Process"
    ),

    result_ui = tagList(
      tags$p("Step 2 outputs (placeholder)."),
      downloadButton(ns("download_output"), "Download output")
    )
  )
}

mod_step2_server <- function(id, state) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$process, {
      state$done(TRUE)
      showNotification("Step 2 finished (placeholder)", type = "message")
    })

    output$download_output <- downloadHandler(
      filename = function() {
        "step2_output_placeholder.txt"
      },
      content = function(file) {
        writeLines("Placeholder output for Step 2.", con = file)
      }
    )
  })
}
