# Launch the capstone Shiny app from the repository root:
#   Rscript run_app.R
# Or in R (repo root):  source("run_app.R", chdir = TRUE)

args <- commandArgs(trailingOnly = FALSE)
file_flags <- grep("^--file=", args, value = TRUE)
repo_root <- if (length(file_flags)) {
  dirname(normalizePath(sub("^--file=", "", file_flags[[1]]), winslash = "/"))
} else {
  normalizePath(getwd(), winslash = "/")
}

app_dir <- file.path(repo_root, "app")
if (!file.exists(file.path(app_dir, "global.R"))) {
  stop("Expected app/global.R under repo root: ", repo_root, call. = FALSE)
}

if (!requireNamespace("shiny", quietly = TRUE)) {
  utils::install.packages("shiny", repos = "https://cloud.r-project.org")
}

shiny::runApp(appDir = app_dir, launch.browser = TRUE)
