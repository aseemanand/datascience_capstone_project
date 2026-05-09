# Root entrypoint for hosted Shiny (shinyapps.io / Posit Connect), matching the pattern of
# https://github.com/shelbybachman/data-science-capstone — publish from the repo root so `R/`
# stays on the bundle path (see scripts/deploy_shinyapps.R).
#
# Local:   shiny::runApp()   # with Working Directory = project root
# Or:      shiny::runApp("app")
#
suppressPackageStartupMessages(library(shiny))
shinyAppDir("app")
