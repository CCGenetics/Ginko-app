# app/modules/mod_step4.R

library(shiny)

source("modules/mod_step_frame.R")
step4_md <- file.path("content", "steps", "step4.md")

mod_step4_ui <- function(id) {
  ns <- NS(id)

  step_frame_ui(
    id = id,
    title = "04 — Country report",

    description_ui = tagList(
      tags$p(
        "Generates a country-level report summarizing genetic diversity indicators."
      ),
      includeMarkdown(step4_md)
    ),

    params_ui = tagList(
      textInput(
        inputId = ns("country_name"),
        label = "Country name",
        value = ""
      )
    ),

    process_ui = actionButton(
      inputId = ns("process"),
      label = "Process"
    ),

    result_ui = tagList(
      tags$p("Step 4 outputs (placeholder)."),
      downloadButton(ns("download_report"), "Download report")
    )
  )
}

mod_step4_server <- function(id, state) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$process, {
      state$done(TRUE)
      showNotification(
        paste(
          "Step 4 finished (placeholder). Country:",
          ifelse(nzchar(input$country_name), input$country_name, "(not specified)")
        ),
        type = "message"
      )
    })

    output$download_report <- downloadHandler(
      filename = function() {
        "step4_country_report_placeholder.txt"
      },
      content = function(file) {
        writeLines(
          paste("Placeholder country report. Country:", input$country_name),
          con = file
        )
      }
    )
  })
}
