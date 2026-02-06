# app/modules/mod_step_frame.R
#
# Shared UI template for pipeline steps.
# Provides consistent layout with collapsible sections.

source("content/ui_strings.R")

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

      tags$h4(LABEL_DESCRIPTION),
      description_ui,

      tags$h4(LABEL_PARAMETERS),
      if (is.null(params_ui)) tags$p(STATUS_NO_PARAMS) else params_ui,

      tags$h4(LABEL_PROCESS),
      process_ui,

      tags$h4(LABEL_RESULT),
      if (is.null(result_ui)) tags$p(STATUS_NO_RESULTS) else result_ui
    )
  )
}
