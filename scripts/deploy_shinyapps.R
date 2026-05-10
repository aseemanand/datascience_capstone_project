#!/usr/bin/env Rscript
# Deploy the next-word app to https://www.shinyapps.io/
# Prerequisites:
#   1. rsconnect account: rsconnect::setAccountInfo(...) once per machine
#   2. SwiftKey data at repo root (zip or final/en_US/) so build_app_lm.R can run
# Run from repository root:
#   Rscript scripts/deploy_shinyapps.R

proj_root <- normalizePath(".")
if (!file.exists(file.path(proj_root, "app.R"))) {
  stop("Run from the repository root (expects app.R).", call. = FALSE)
}

lm_path <- file.path(proj_root, "app", "data", "lm_app.rds")
if (!file.exists(lm_path)) {
  build_sh <- file.path(proj_root, "scripts", "build_app_lm.R")
  if (!file.exists(build_sh)) {
    stop("Missing ", lm_path, " and no ", build_sh, call. = FALSE)
  }
  message("Building ", lm_path, " (run scripts/build_app_lm.R manually to tune sample size) ...")
  rc <- system2("Rscript", build_sh, wait = TRUE)
  if (is.null(rc) || rc != 0L) {
    stop(
      "build_app_lm.R failed (exit ", rc, "). Ensure Coursera-SwiftKey.zip or final/en_US/*.txt exists.",
      call. = FALSE
    )
  }
}
if (!file.exists(lm_path)) {
  stop("Still missing ", lm_path, " after build.", call. = FALSE)
}

if (!requireNamespace("rsconnect", quietly = TRUE)) {
  stop("Install rsconnect: install.packages('rsconnect')", call. = FALSE)
}

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
  appName = "Next-Word-Predictor",
  lint = FALSE
)

do.call(rsconnect::deployApp, args_deploy)
