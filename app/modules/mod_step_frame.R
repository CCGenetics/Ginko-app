# app/modules/mod_step_frame.R

step_frame_ui <- function(
  id,
  title,
  description_ui,
  params_ui = NULL,
  process_ui,
  result_ui = NULL
) {
  ns <- NS(id)

  tags$details(
    class = "step-box",
    tags$summary(title),

    tags$div(
      class = "step-content",

      tags$h4("Description"),
      description_ui,

      tags$h4("Parameters"),
      if (is.null(params_ui)) tags$p("No parameters.") else params_ui,

      tags$h4("Process"),
      process_ui,

      tags$h4("Result"),
      if (is.null(result_ui)) tags$p("No results yet.") else result_ui
    )
  )
}
