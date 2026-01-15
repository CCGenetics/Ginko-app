# app/modules/mod_step3.R

library(shiny)

source("modules/mod_step_frame.R")
step3_md <- file.path("content", "steps", "step3.md")

mod_step3_ui <- function(id) {
  ns <- NS(id)

  step_frame_ui(
    id = id,
    title = "03 — Estimate indicators",

    description_ui = tagList(
      tags$p(
        "Calculates genetic diversity indicators required by the ",
        "Global Biodiversity Framework (Ne 500, PM, DNA-based)."
      ),
      includeMarkdown(step3_md)
    ),

    params_ui = tagList(
      numericInput(
        inputId = ns("ne_threshold"),
        label = "Ne threshold",
        value = 500,
        min = 1
      )
    ),

    process_ui = actionButton(
      inputId = ns("process"),
      label = "Process"
    ),

    result_ui = tagList(
      tags$p("Step 3 outputs (placeholder)."),
      downloadButton(ns("download_output"), "Download output")
    )
  )
}

mod_step3_server <- function(id, state) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$process, {
      state$done(TRUE)
      showNotification(
        paste("Step 3 finished (placeholder). Ne threshold =", input$ne_threshold),
        type = "message"
      )
    })

    output$download_output <- downloadHandler(
      filename = function() {
        "step3_output_placeholder.txt"
      },
      content = function(file) {
        writeLines(
          paste("Placeholder output for Step 3. Ne threshold:", input$ne_threshold),
          con = file
        )
      }
    )
  })
}
