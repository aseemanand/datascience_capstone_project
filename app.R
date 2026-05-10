# Root entrypoint for hosted Shiny (shinyapps.io / Posit Connect).
# Publish from the repository root so `R/` stays on the bundle path (see scripts/deploy_shinyapps.R).
#
# Local:   shiny::runApp()   # with Working Directory = project root
# Or:      shiny::runApp("app")
#
suppressPackageStartupMessages(library(shiny))
shinyAppDir("app")
