# N-gram backoff LM pipeline (tokenization -> train -> predict -> evaluation helpers).
# When sourcing from Shiny (`app/`), set env DATASCIENCE_CAPSTONE_ROOT to the repo root.

.capstone_root <- Sys.getenv("DATASCIENCE_CAPSTONE_ROOT", unset = ".")
source(file.path(.capstone_root, "R", "milestone_text_utils.R"), encoding = "UTF-8")
suppressPackageStartupMessages(library(data.table))
source(file.path(.capstone_root, "R", "lm_ngram_backoff.R"), encoding = "UTF-8")
source(file.path(.capstone_root, "R", "lm_rank_eval.R"), encoding = "UTF-8")
