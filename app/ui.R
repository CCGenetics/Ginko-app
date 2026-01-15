# app/ui.R

library(shiny)

source("modules/mod_step_frame.R")
source("modules/mod_step1.R")
source("modules/mod_step2.R")
source("modules/mod_step3.R")
source("modules/mod_step4.R")

ui <- fluidPage(
  tags$head(
    tags$link(
      rel = "stylesheet",
      type = "text/css",
      href = "styles.css"
    )
  ),

  tags$h1("Ginko"),

  # ---- STEP 00 ------------------------------------------------------------
  tags$details(
    open = TRUE,
    class = "step-box",

    tags$summary("00 — Upload data"),

    tags$h4("Description"),
    tags$p("Upload raw CSV exported from KoboToolbox."),

    fileInput(
      inputId = "upload_data",
      label = "Upload CSV file",
      accept = ".csv"
    )
  ),

  # ---- STEPS 01–04 --------------------------------------
  mod_step1_ui("step1"),
  mod_step2_ui("step2"),
  mod_step3_ui("step3"),
  mod_step4_ui("step4")
)
