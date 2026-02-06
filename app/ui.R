# app/ui.R

library(shiny)

source("content/ui_strings.R")
source("modules/mod_step_frame.R")
source("modules/mod_step1.R")
source("modules/mod_step2.R")
source("modules/mod_step3.R")
source("modules/mod_step4.R")

about_md <- file.path("content", "steps", "about.md")
step0_md <- file.path("content", "steps", "step0.md")

ui <- fluidPage(
  tags$head(
    tags$link(
      rel = "stylesheet",
      type = "text/css",
      href = "styles.css"
    )
  ),

  tags$h1(APP_TITLE),

  # About box
  tags$details(
    open = FALSE,
    class = "step-box",

    tags$summary(ABOUT_TITLE),

    if (file.exists(about_md)) {
      includeMarkdown(about_md)
    } else {
      tags$em(paste("Missing markdown file:", about_md))
    }
  ),

  # Step 0 - Upload data
  tags$details(
    open = TRUE,
    class = "step-box",

    tags$summary(STEP0_TITLE),

    if (file.exists(step0_md)) {
      includeMarkdown(step0_md)
    } else {
      tags$em(paste("Missing markdown file:", step0_md))
    },

    fileInput(
      inputId = "upload_data",
      label = LABEL_UPLOAD_CSV,
      accept = ".csv"
    )
  ),

  # Steps 1-4
  mod_step1_ui("step1"),
  mod_step2_ui("step2"),
  mod_step3_ui("step3"),
  mod_step4_ui("step4")
)
