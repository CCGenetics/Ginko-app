# app/app.R
#
# Entry point for the Ginko Shiny application.
# Web interface for the Ginko-Rfun genetic diversity indicators pipeline.

source("R/00_deps.R")

source("ui.R")
source("server.R")

shiny::shinyApp(
  ui = ui,
  server = server
)
