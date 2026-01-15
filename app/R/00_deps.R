# app/R/00_deps.R

packages <- c(
  "shiny",
  "markdown",
  "rmarkdown",
  "knitr",

  # Ginko step1 Rmd deps
  "tidyr",
  "dplyr",
  "magrittr",
  "stringr",
  "ggplot2",
  "utile.tools"
)

installed <- rownames(installed.packages())
to_install <- setdiff(packages, installed)

if (length(to_install) > 0) {
  install.packages(
    to_install,
    repos = "https://cloud.r-project.org"
  )
}
