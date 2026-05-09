#!/usr/bin/env Rscript
# Deploy the next-word app to https://www.shinyapps.io/ (see shelbybachman README pattern).
# Prerequisites:
#   1. rsconnect account: rsconnect::setAccountInfo(...) once per machine
#   2. Model artifact:    Rscript scripts/build_app_lm.R
# Run from repository root:
#   Rscript scripts/deploy_shinyapps.R
# Optional app name:
#   Rscript scripts/deploy_shinyapps.R My-App-Name

proj_root <- normalizePath(".")
if (!file.exists(file.path(proj_root, "app.R"))) {
  stop("Run from the repository root (expects app.R).", call. = FALSE)
}

lm_path <- file.path(proj_root, "app", "data", "lm_app.rds")
if (!file.exists(lm_path)) {
  stop("Missing ", lm_path, " — run: Rscript scripts/build_app_lm.R", call. = FALSE)
}

if (!requireNamespace("rsconnect", quietly = TRUE)) {
  stop("Install rsconnect: install.packages('rsconnect')", call. = FALSE)
}

argv <- commandArgs(trailingOnly = TRUE)
app_name <- if (length(argv) >= 1L) argv[[1]] else NULL

app_paths <- file.path(
  "app",
  list.files(file.path(proj_root, "app"), recursive = TRUE, full.names = FALSE)
)
r_paths <- file.path(
  "R",
  dir(file.path(proj_root, "R"), pattern = "\\.[rR]$", full.names = FALSE)
)

bundle <- unique(c("app.R", app_paths, r_paths))

drop <- !file.exists(file.path(proj_root, bundle))
if (any(drop)) {
  stop("Missing bundle files: ", paste(bundle[drop], collapse = ", "), call. = FALSE)
}

args_deploy <- list(
  appDir = proj_root,
  appPrimaryDoc = "app.R",
  appFiles = bundle,
  lint = FALSE
)
if (!is.null(app_name)) {
  args_deploy$appName <- app_name
}

do.call(rsconnect::deployApp, args_deploy)
