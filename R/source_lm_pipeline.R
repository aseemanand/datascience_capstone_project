# N-gram backoff LM pipeline (tokenization -> train -> predict -> evaluation helpers).

source(file.path("R", "milestone_text_utils.R"), encoding = "UTF-8")
suppressPackageStartupMessages(library(data.table))
source(file.path("R", "lm_ngram_backoff.R"), encoding = "UTF-8")
source(file.path("R", "lm_bachman_eval.R"), encoding = "UTF-8")
