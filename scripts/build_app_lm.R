#!/usr/bin/env Rscript
# Build a pruned Katz n-gram LM for the Shiny app and save to app/data/lm_app.rds.
# Run from the repository root:  Rscript scripts/build_app_lm.R

argv <- commandArgs(trailingOnly = TRUE)
lines_per_source <- if (length(argv) >= 1L) as.integer(argv[[1]]) else 3500L

root <- getwd()
if (!file.exists(file.path(root, "R", "source_lm_pipeline.R"))) {
  stop("Run this script from the datascience_capstone_project repository root.", call. = FALSE)
}

suppressPackageStartupMessages({
  if (!requireNamespace("data.table", quietly = TRUE)) {
    install.packages("data.table", repos = "https://cloud.r-project.org")
  }
})

source(file.path(root, "R", "milestone_paths.R"), encoding = "UTF-8")
source(file.path(root, "R", "milestone_load_samples.R"), encoding = "UTF-8")
source(file.path(root, "R", "source_lm_pipeline.R"), encoding = "UTF-8")

swiftkey <- resolve_swiftkey_en(root)
assert_swiftkey_data_available(swiftkey)

raw_lines <- assemble_head_samples(swiftkey, lines_per_source)$text
tok <- tokenize_lines_lm(raw_lines)

lm_app <- build_ngram_lm(
  tok,
  min_freq_uni = 1L,
  min_freq_bi = 3L,
  min_freq_tri = 3L,
  min_freq_quad = 3L
)

out_dir <- file.path(root, "app", "data")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
out_path <- file.path(out_dir, "lm_app.rds")

meta <- list(
  lines_per_source = lines_per_source,
  n_lines = length(raw_lines),
  katz_discount_default = 0.75,
  prune_note = "Higher-order n-grams kept only when count >= 3 (see model_accuracy_report.Rmd)",
  n_parameters = lm_n_parameters(lm_app),
  vocab_size = lm_app$vocab_size,
  built_at = format(Sys.time(), tz = "UTC", usetz = TRUE)
)

saveRDS(list(lm = lm_app, meta = meta), out_path)
message("Saved ", out_path, " (", round(file.info(out_path)$size / 1024^2, 2), " MiB)")
message("Rows stored (uni–quad): ", meta$n_parameters)
