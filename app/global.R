# SwiftKey-style next-word demo (Katz backoff LM shared with model_accuracy_report.Rmd).

# Install missing deps when opened from RStudio / runApp (terminal installs: use R -e 'install.packages(...)').
.app_pkgs <- c("shiny", "shinythemes", "ggplot2", "scales", "data.table")
missing_pkgs <- .app_pkgs[!vapply(.app_pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_pkgs)) {
  utils::install.packages(missing_pkgs, repos = "https://cloud.r-project.org")
}

suppressPackageStartupMessages({
  library(shiny)
  library(shinythemes)
  library(ggplot2)
  library(scales)
})

`%||%` <- function(a, b) if (!is.null(a)) a else b

# Repo root: parent of app/ when Shiny runs global.R (local + shinyapps.io bundle layout).
repo_root <- Sys.getenv("DATASCIENCE_CAPSTONE_ROOT", unset = "")
if (!nzchar(repo_root)) {
  wd <- normalizePath(getwd(), winslash = "/")
  repo_root <- if (basename(wd) == "app") dirname(wd) else wd
}
repo_root <- normalizePath(repo_root, winslash = "/")
Sys.setenv(DATASCIENCE_CAPSTONE_ROOT = repo_root)
source(file.path(repo_root, "R", "source_lm_pipeline.R"), encoding = "UTF-8")

LM_PATH <- file.path(getwd(), "data", "lm_app.rds")
if (file.exists(LM_PATH)) {
  blob <- readRDS(LM_PATH)
  LM_OBJ <- blob$lm
  LM_META <- blob$meta %||% list(note = "Re-save lm_app.rds with scripts/build_app_lm.R for metadata.")
  LM_READY <- TRUE
} else {
  LM_OBJ <- NULL
  LM_META <- NULL
  LM_READY <- FALSE
}

normalize_input_tokens <- function(text) {
  txt <- trimws(text)
  if (!nzchar(txt)) {
    return(character())
  }
  unlist(extract_alpha_tokens(txt), use.names = FALSE)
}
