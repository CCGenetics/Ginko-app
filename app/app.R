# app/app.R

source("R/00_deps.R")

source("modules/mod_step_frame.R")
source("modules/mod_step1.R")
source("modules/mod_step2.R")
source("modules/mod_step3.R")
source("modules/mod_step4.R")

source("ui.R")
source("server.R")

shiny::shinyApp(
  ui = ui,
  server = server
)
