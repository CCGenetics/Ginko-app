# app/server.R

library(shiny)

source("modules/mod_step_frame.R")
source("modules/mod_step1.R")
source("modules/mod_step2.R")
source("modules/mod_step3.R")
source("modules/mod_step4.R")

server <- function(input, output, session) {

  # ---- session-scoped sandbox --------------------------------------------
  session_id <- session$token
  base_dir   <- file.path(tempdir(), "ginko", session_id)
  input_dir  <- file.path(base_dir, "input")
  dir.create(input_dir, recursive = TRUE, showWarnings = FALSE)

  session$onSessionEnded(function() {
    unlink(base_dir, recursive = TRUE, force = TRUE)
  })

  # ---- upload -> save to session dir -------------------------------------
  observeEvent(input$upload_data, {
    req(input$upload_data)
    req(input$upload_data$datapath)

    dest_file <- file.path(input_dir, "00_raw_data.csv")

    ok <- file.copy(
      from = input$upload_data$datapath,
      to   = dest_file,
      overwrite = TRUE
    )

    if (!ok) stop("Failed to save uploaded file")

    showNotification(paste("Uploaded ->", dest_file), type = "message")
  })

  # ---- Step 1 (real) ------------------------------------------------------
  mod_step1_server(
    id = "step1",
    paths = list(
      base_dir  = base_dir,
      input_dir = input_dir
    )
  )

  # ---- Steps 2–4 (placeholders; keep your current flow wiring) -----------
  step1_done <- reactiveVal(FALSE)
  step2_done <- reactiveVal(FALSE)
  step3_done <- reactiveVal(FALSE)

  mod_step2_server("step2", state = list(done = step1_done))
  mod_step3_server("step3", state = list(done = step2_done))
  mod_step4_server("step4", state = list(done = step3_done))
}
