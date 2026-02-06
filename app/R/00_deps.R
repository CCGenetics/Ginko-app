# app/R/00_deps.R
#
# Package dependencies for the Ginko Shiny application.
# Installs missing packages on startup.

packages <- c(
  # Shiny framework
  "shiny",
  "markdown",
  "rmarkdown",
  "knitr",

  # Data manipulation (used by Ginko-Rfun scripts)
  "tidyr",
  "dplyr",
  "magrittr",
  "stringr",
  "ggplot2",
  "utile.tools",
  "viridis"
)

installed <- rownames(installed.packages())
to_install <- setdiff(packages, installed)

if (length(to_install) > 0) {
  message("Installing missing packages: ", paste(to_install, collapse = ", "))
  install.packages(to_install, repos = "https://cloud.r-project.org")
}

invisible(lapply(packages, library, character.only = TRUE))
